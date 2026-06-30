class PaymentModel {
  final String id;
  final String clientId;
  final double amount;
  final String paymentMethod; // 'cash', 'bank_transfer', 'check'
  final String notes;
  final String recordedByUid;
  final DateTime date;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    required this.recordedByUid,
    required this.date,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      clientId: map['clientId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      notes: map['notes'] ?? '',
      recordedByUid: map['recordedByUid'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'recordedByUid': recordedByUid,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
