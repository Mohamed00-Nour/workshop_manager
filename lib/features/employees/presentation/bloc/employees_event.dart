import '../../domain/models/employee_model.dart';
import '../../domain/models/attendance_model.dart';
import '../../domain/models/payroll_config_model.dart';

abstract class EmployeesEvent {}

class LoadEmployeesData extends EmployeesEvent {
  final String? initialDate; // defaults to today (YYYY-MM-DD)
  LoadEmployeesData({this.initialDate});
}

class LoadAttendanceForDateEvent extends EmployeesEvent {
  final String date; // YYYY-MM-DD
  LoadAttendanceForDateEvent(this.date);
}

class AddEmployeeEvent extends EmployeesEvent {
  final EmployeeModel employee;
  AddEmployeeEvent(this.employee);
}

class UpdateEmployeeEvent extends EmployeesEvent {
  final EmployeeModel employee;
  UpdateEmployeeEvent(this.employee);
}

class DeleteEmployeeEvent extends EmployeesEvent {
  final String id;
  DeleteEmployeeEvent(this.id);
}

class SaveAttendanceRecordEvent extends EmployeesEvent {
  final AttendanceRecord record;
  SaveAttendanceRecordEvent(this.record);
}

class SavePayrollConfigEvent extends EmployeesEvent {
  final PayrollConfig config;
  SavePayrollConfigEvent(this.config);
}

class CalculateWeeklyPayrollEvent extends EmployeesEvent {
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  CalculateWeeklyPayrollEvent({required this.startDate, required this.endDate});
}
