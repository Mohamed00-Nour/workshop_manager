class PayrollConfig {
  final int graceMinutes;
  final double overtimeHourlyRate;
  final double lateDeductionHourlyRate;

  PayrollConfig({
    required this.graceMinutes,
    required this.overtimeHourlyRate,
    required this.lateDeductionHourlyRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'graceMinutes': graceMinutes,
      'overtimeHourlyRate': overtimeHourlyRate,
      'lateDeductionHourlyRate': lateDeductionHourlyRate,
    };
  }

  factory PayrollConfig.fromMap(Map<String, dynamic> map) {
    return PayrollConfig(
      graceMinutes: map['graceMinutes'] ?? 60,
      overtimeHourlyRate: (map['overtimeHourlyRate'] ?? 50.0).toDouble(),
      lateDeductionHourlyRate: (map['lateDeductionHourlyRate'] ?? 40.0).toDouble(),
    );
  }

  PayrollConfig copyWith({
    int? graceMinutes,
    double? overtimeHourlyRate,
    double? lateDeductionHourlyRate,
  }) {
    return PayrollConfig(
      graceMinutes: graceMinutes ?? this.graceMinutes,
      overtimeHourlyRate: overtimeHourlyRate ?? this.overtimeHourlyRate,
      lateDeductionHourlyRate: lateDeductionHourlyRate ?? this.lateDeductionHourlyRate,
    );
  }
}
