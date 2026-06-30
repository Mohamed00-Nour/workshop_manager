class EmployeeModel {
  final String id;
  final String name;
  final String phone;
  final double baseWeeklySalary;
  final double standardHoursPerDay;
  final DateTime createdAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.baseWeeklySalary,
    this.standardHoursPerDay = 8.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'baseWeeklySalary': baseWeeklySalary,
      'standardHoursPerDay': standardHoursPerDay,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EmployeeModel(
      id: documentId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      baseWeeklySalary: (map['baseWeeklySalary'] ?? 0.0).toDouble(),
      standardHoursPerDay: (map['standardHoursPerDay'] ?? 8.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? phone,
    double? baseWeeklySalary,
    double? standardHoursPerDay,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      baseWeeklySalary: baseWeeklySalary ?? this.baseWeeklySalary,
      standardHoursPerDay: standardHoursPerDay ?? this.standardHoursPerDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
