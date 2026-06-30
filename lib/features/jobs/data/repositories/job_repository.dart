import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import '../../../../core/services/cache_service.dart';
import '../../../clients/data/repositories/client_repository.dart';
import '../../domain/models/job_model.dart';

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CacheService _cacheService = CacheService();
  final ClientRepository _clientRepository = ClientRepository();

  // Get jobs for a specific client (Cached first, then server background fetch)
  Future<List<JobModel>> getJobsCached(String clientId) async {
    final cached = _cacheService.getJobs(clientId);
    return cached.map((map) => JobModel.fromMap(map, map['id'])).toList();
  }

  Future<List<JobModel>> fetchJobsFromServer(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> jobMaps = [];
      final List<JobModel> jobs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        jobMaps.add(data);
        jobs.add(JobModel.fromMap(data, doc.id));
      }

      await _cacheService.saveJobs(jobMaps);
      return jobs;
    } catch (e) {
      print('Error fetching jobs: $e');
      return getJobsCached(clientId);
    }
  }

  // Compress image to save bandwidth and Firebase Storage quota
  Future<File> compressImage(File file) async {
    try {
      final imageBytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return file;

      // Resize the image to a maximum width of 1024px while maintaining aspect ratio
      img.Image resizedImage;
      if (decodedImage.width > 1024) {
        resizedImage = img.copyResize(decodedImage, width: 1024);
      } else {
        resizedImage = decodedImage;
      }

      // Compress with 60% quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: 60);
      
      // Save to a temporary file
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (e) {
      print('Image compression failed, using original file: $e');
      return file;
    }
  }

  Future<void> addJob(JobModel job, File? imageFile) async {
    final docRef = _firestore.collection('jobs').doc();
    String imageUrl = '';

    if (imageFile != null) {
      final compressedFile = await compressImage(imageFile);
      final ref = _storage.ref().child('job_images/${job.clientId}/${docRef.id}.jpg');
      
      final uploadTask = await ref.putFile(compressedFile);
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    final jobData = job.toMap();
    jobData['imageUrl'] = imageUrl;

    // Save job document
    await docRef.set(jobData);

    // Save to local cache
    jobData['id'] = docRef.id;
    await _cacheService.saveJob(jobData);

    // Atomically increment client's total cost and update current balance
    await _clientRepository.adjustClientBalances(job.clientId, job.cost, 0.0);
  }

  Future<void> updateJobStatus(String jobId, String clientId, String status) async {
    final docRef = _firestore.collection('jobs').doc(jobId);
    await docRef.update({'status': status});

    // Update in cache
    final cached = _cacheService.getJobs(clientId);
    final jobMap = cached.firstWhere((element) => element['id'] == jobId, orElse: () => {});
    if (jobMap.isNotEmpty) {
      jobMap['status'] = status;
      await _cacheService.saveJob(jobMap);
    }
  }

  Future<void> deleteJob(String jobId, String clientId, double cost) async {
    await _firestore.collection('jobs').doc(jobId).delete();
    
    // Remove from cache
    // Wait, cache delete is done by cleaning box or we can just ignore it as it will refresh, 
    // but let's delete the key from the box. We will clear the specific item.
    // In our cache_service we put the jobs in `_jobsBox` by job['id']. So we can delete by ID:
    // Box box = await Hive.openBox('jobs'); await box.delete(jobId);
    // Since CacheService opens the box, let's add a delete helper or open it here.
    // Delete from local cache
    try {
      if (Hive.isBoxOpen('jobs')) {
        await Hive.box('jobs').delete(jobId);
      }
    } catch (_) {}

    // Atomically decrement client's total cost and update current balance
    await _clientRepository.adjustClientBalances(clientId, -cost, 0.0);
  }
}
