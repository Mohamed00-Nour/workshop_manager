import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/payroll_config_model.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Employees ---
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final snapshot = await _firestore
          .collection('employees')
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => EmployeeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final docRef = _firestore.collection('employees').doc();
    await docRef.set(employee.toMap());
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await _firestore
        .collection('employees')
        .doc(employee.id)
        .update(employee.toMap());
  }

  Future<void> deleteEmployee(String id) async {
    await _firestore.collection('employees').doc(id).delete();
    // Also delete their attendance records
    final attendanceSnap = await _firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (var doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Attendance ---
  Future<List<AttendanceRecord>> getAttendanceForDate(String date) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching attendance for date $date: $e');
      return [];
    }
  }

  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    // Unique document ID to avoid duplicate records for the same employee on the same date: employeeId_date
    final docId = '${record.employeeId}_${record.date}';
    await _firestore
        .collection('attendance')
        .doc(docId)
        .set(record.toMap(), SetOptions(merge: true));
  }

  Future<List<AttendanceRecord>> getAttendanceForEmployeeInPeriod(
      String employeeId, String startDate, String endDate) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching attendance in period: $e');
      return [];
    }
  }

  // --- Payroll Config ---
  Future<PayrollConfig> getPayrollConfig() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('attendance_config')
          .get();
      if (doc.exists && doc.data() != null) {
        return PayrollConfig.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error fetching payroll config: $e');
    }
    // Return default values
    return PayrollConfig(
      graceMinutes: 60,
      overtimeHourlyRate: 50.0,
      lateDeductionHourlyRate: 40.0,
    );
  }

  Future<void> savePayrollConfig(PayrollConfig config) async {
    await _firestore
        .collection('settings')
        .doc('attendance_config')
        .set(config.toMap(), SetOptions(merge: true));
  }
}
