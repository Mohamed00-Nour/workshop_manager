import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/cache_service.dart';
import '../../../clients/data/repositories/client_repository.dart';
import '../../domain/models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  final ClientRepository _clientRepository = ClientRepository();

  Future<List<PaymentModel>> getPaymentsCached(String clientId) async {
    final cached = _cacheService.getPayments(clientId);
    return cached.map((map) => PaymentModel.fromMap(map, map['id'])).toList();
  }

  Future<List<PaymentModel>> fetchPaymentsFromServer(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> payMaps = [];
      final List<PaymentModel> payments = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        payMaps.add(data);
        payments.add(PaymentModel.fromMap(data, doc.id));
      }

      await _cacheService.savePayments(payMaps);
      return payments;
    } catch (e) {
      print('Error fetching payments: $e');
      return getPaymentsCached(clientId);
    }
  }

  Future<void> addPayment(PaymentModel payment) async {
    final docRef = _firestore.collection('payments').doc();
    final payData = payment.toMap();

    // Save payment document
    await docRef.set(payData);

    // Save to cache
    payData['id'] = docRef.id;
    await _cacheService.savePayment(payData);

    // Atomically increment client's paid sum and adjust balance
    await _clientRepository.adjustClientBalances(payment.clientId, 0.0, payment.amount);
  }

  Future<void> deletePayment(String paymentId, String clientId, double amount) async {
    await _firestore.collection('payments').doc(paymentId).delete();

    // Remove from cache
    try {
      if (Hive.isBoxOpen('payments')) {
        await Hive.box('payments').delete(paymentId);
      }
    } catch (_) {}

    // Atomically decrement client's paid sum and adjust balance
    await _clientRepository.adjustClientBalances(clientId, 0.0, -amount);
  }
}
