import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_helper.dart';
import '../../data/repositories/payment_repository.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final PaymentRepository _paymentRepository;

  PaymentsBloc(this._paymentRepository) : super(PaymentsInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<AddPaymentRequested>(_onAddPayment);
    on<DeletePaymentRequested>(_onDeletePayment);
  }

  Future<void> _onLoadPayments(LoadPayments event, Emitter<PaymentsState> emit) async {
    if (state is! PaymentsLoaded) {
      emit(PaymentsLoading());
    }

    try {
      final cached = await _paymentRepository.getPaymentsCached(event.clientId);
      if (cached.isNotEmpty) {
        emit(PaymentsLoaded(cached));
      }

      if (event.refreshFromServer || cached.isEmpty) {
        final server = await _paymentRepository.fetchPaymentsFromServer(event.clientId);
        emit(PaymentsLoaded(server));
      }
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onAddPayment(AddPaymentRequested event, Emitter<PaymentsState> emit) async {
    try {
      await _paymentRepository.addPayment(event.payment);
      add(LoadPayments(clientId: event.payment.clientId, refreshFromServer: false));

      // Trigger secure FCM V1 notification
      await NotificationHelper().triggerNotification(
        title: 'Payment Received',
        body: 'Amount: ${event.payment.amount} EGP | Method: ${event.payment.paymentMethod.toUpperCase()}',
        topic: 'workshop_updates',
      );
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onDeletePayment(DeletePaymentRequested event, Emitter<PaymentsState> emit) async {
    try {
      await _paymentRepository.deletePayment(event.paymentId, event.clientId, event.amount);
      add(LoadPayments(clientId: event.clientId, refreshFromServer: false));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }
}
