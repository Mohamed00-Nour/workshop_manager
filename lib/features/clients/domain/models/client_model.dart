class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String company;
  final double totalJobsCost;
  final double totalPaidAmount;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.company,
    this.totalJobsCost = 0.0,
    this.totalPaidAmount = 0.0,
    this.currentBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'] ?? '',
      totalJobsCost: (map['totalJobsCost'] ?? 0.0).toDouble(),
      totalPaidAmount: (map['totalPaidAmount'] ?? 0.0).toDouble(),
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'company': company,
      'totalJobsCost': totalJobsCost,
      'totalPaidAmount': totalPaidAmount,
      'currentBalance': currentBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
