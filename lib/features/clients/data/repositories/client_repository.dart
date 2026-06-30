import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/models/client_model.dart';

class ClientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();

  // Load clients from local Hive cache first, then sync from Firestore in the background
  Future<List<ClientModel>> getClientsCached() async {
    final cachedMaps = _cacheService.getClients();
    return cachedMaps.map((map) => ClientModel.fromMap(map, map['id'])).toList();
  }

  // Fetch updated clients from Firestore and save them to Hive cache
  Future<List<ClientModel>> fetchClientsFromServer() async {
    try {
      final snapshot = await _firestore
          .collection('clients')
          .orderBy('updatedAt', descending: true)
          .limit(100) // limit total cached list length to save space
          .get();

      final List<Map<String, dynamic>> clientMaps = [];
      final List<ClientModel> clients = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        clientMaps.add(data);
        clients.add(ClientModel.fromMap(data, doc.id));
      }

      await _cacheService.saveClients(clientMaps);
      return clients;
    } catch (e) {
      print('Error fetching clients: $e');
      // If server fetch fails, return cached list
      return getClientsCached();
    }
  }

  Future<ClientModel?> getClient(String id) async {
    // Try cache first
    final cached = _cacheService.getClients().firstWhere(
          (c) => c['id'] == id,
          orElse: () => {},
        );
    
    if (cached.isNotEmpty) {
      return ClientModel.fromMap(cached, id);
    }

    // Server fallback
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final client = ClientModel.fromMap(data, doc.id);
        await _cacheService.saveClient(data);
        return client;
      }
    } catch (e) {
      print('Error fetching client details: $e');
    }
    return null;
  }

  Future<void> addClient(ClientModel client) async {
    final docRef = _firestore.collection('clients').doc();
    final clientData = client.toMap();
    clientData['updatedAt'] = DateTime.now().toIso8601String();
    
    await docRef.set(clientData);

    // Save to cache
    clientData['id'] = docRef.id;
    await _cacheService.saveClient(clientData);
  }

  Future<void> updateClient(ClientModel client) async {
    final docRef = _firestore.collection('clients').doc(client.id);
    final clientData = client.toMap();
    clientData['updatedAt'] = DateTime.now().toIso8601String();

    await docRef.update(clientData);

    // Save to cache
    clientData['id'] = client.id;
    await _cacheService.saveClient(clientData);
  }

  Future<void> deleteClient(String id) async {
    await _firestore.collection('clients').doc(id).delete();
    await _cacheService.deleteClient(id);
  }

  // Atomically update client balance on server and update local cache
  Future<void> adjustClientBalances(String clientId, double costDelta, double paidDelta) async {
    final docRef = _firestore.collection('clients').doc(clientId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final currentCost = (data['totalJobsCost'] ?? 0.0).toDouble();
        final currentPaid = (data['totalPaidAmount'] ?? 0.0).toDouble();
        
        final newCost = currentCost + costDelta;
        final newPaid = currentPaid + paidDelta;
        final newBalance = newCost - newPaid;

        transaction.update(docRef, {
          'totalJobsCost': newCost,
          'totalPaidAmount': newPaid,
          'currentBalance': newBalance,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Update local cache inside transaction
        data['id'] = clientId;
        data['totalJobsCost'] = newCost;
        data['totalPaidAmount'] = newPaid;
        data['currentBalance'] = newBalance;
        data['updatedAt'] = DateTime.now().toIso8601String();
        await _cacheService.saveClient(data);
      }
    });
  }
}
