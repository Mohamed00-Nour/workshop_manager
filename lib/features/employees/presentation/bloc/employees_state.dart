import '../../domain/models/employee_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/payroll_config_model.dart';

abstract class EmployeesState {}

class EmployeesInitial extends EmployeesState {}

class EmployeesLoading extends EmployeesState {}

class EmployeesLoaded extends EmployeesState {
  final List<EmployeeModel> employees;
  final List<AttendanceRecord> attendanceRecords; // for the currently selected date
  final String selectedDate; // YYYY-MM-DD
  final PayrollConfig config;
  
  // Weekly payroll report state map (employeeId -> list of attendance records in selected week)
  final Map<String, List<AttendanceRecord>> weeklyAttendance;
  final String? payrollStartDate;
  final String? payrollEndDate;

  EmployeesLoaded({
    required this.employees,
    required this.attendanceRecords,
    required this.selectedDate,
    required this.config,
    this.weeklyAttendance = const {},
    this.payrollStartDate,
    this.payrollEndDate,
  });

  EmployeesLoaded copyWith({
    List<EmployeeModel>? employees,
    List<AttendanceRecord>? attendanceRecords,
    String? selectedDate,
    PayrollConfig? config,
    Map<String, List<AttendanceRecord>>? weeklyAttendance,
    String? payrollStartDate,
    String? payrollEndDate,
  }) {
    return EmployeesLoaded(
      employees: employees ?? this.employees,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      selectedDate: selectedDate ?? this.selectedDate,
      config: config ?? this.config,
      weeklyAttendance: weeklyAttendance ?? this.weeklyAttendance,
      payrollStartDate: payrollStartDate ?? this.payrollStartDate,
      payrollEndDate: payrollEndDate ?? this.payrollEndDate,
    );
  }
}

class EmployeesError extends EmployeesState {
  final String message;
  EmployeesError(this.message);
}
