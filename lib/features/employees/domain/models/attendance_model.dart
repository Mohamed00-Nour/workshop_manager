class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final bool isAbsent;
  final String? checkInTime; // "HH:MM"
  final String? checkOutTime; // "HH:MM"
  final int lateMinutes;
  final int overtimeMinutes;
  final String notes;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.isAbsent,
    this.checkInTime,
    this.checkOutTime,
    this.lateMinutes = 0,
    this.overtimeMinutes = 0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'date': date,
      'isAbsent': isAbsent,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'lateMinutes': lateMinutes,
      'overtimeMinutes': overtimeMinutes,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceRecord(
      id: documentId,
      employeeId: map['employeeId'] ?? '',
      date: map['date'] ?? '',
      isAbsent: map['isAbsent'] ?? false,
      checkInTime: map['checkInTime'],
      checkOutTime: map['checkOutTime'],
      lateMinutes: map['lateMinutes'] ?? 0,
      overtimeMinutes: map['overtimeMinutes'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? date,
    bool? isAbsent,
    String? checkInTime,
    String? checkOutTime,
    int? lateMinutes,
    int? overtimeMinutes,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      isAbsent: isAbsent ?? this.isAbsent,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      notes: notes ?? this.notes,
    );
  }
}
