import 'package:equatable/equatable.dart';
import '../../domain/models/payment_model.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentsEvent {
  final String clientId;
  final bool refreshFromServer;

  const LoadPayments({required this.clientId, this.refreshFromServer = false});

  @override
  List<Object?> get props => [clientId, refreshFromServer];
}

class AddPaymentRequested extends PaymentsEvent {
  final PaymentModel payment;
  const AddPaymentRequested(this.payment);

  @override
  List<Object?> get props => [payment];
}

class DeletePaymentRequested extends PaymentsEvent {
  final String paymentId;
  final String clientId;
  final double amount;

  const DeletePaymentRequested({
    required this.paymentId,
    required this.clientId,
    required this.amount,
  });

  @override
  List<Object?> get props => [paymentId, clientId, amount];
}
