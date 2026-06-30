import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/models/attendance_model.dart';
import 'employees_event.dart';
import 'employees_state.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final EmployeeRepository _employeeRepository;

  EmployeesBloc(this._employeeRepository) : super(EmployeesInitial()) {
    on<LoadEmployeesData>(_onLoadEmployeesData);
    on<LoadAttendanceForDateEvent>(_onLoadAttendanceForDate);
    on<AddEmployeeEvent>(_onAddEmployee);
    on<UpdateEmployeeEvent>(_onUpdateEmployee);
    on<DeleteEmployeeEvent>(_onDeleteEmployee);
    on<SaveAttendanceRecordEvent>(_onSaveAttendanceRecord);
    on<SavePayrollConfigEvent>(_onSavePayrollConfig);
    on<CalculateWeeklyPayrollEvent>(_onCalculateWeeklyPayroll);
  }

  Future<void> _onLoadEmployeesData(
      LoadEmployeesData event, Emitter<EmployeesState> emit) async {
    emit(EmployeesLoading());
    try {
      final date = event.initialDate ??
          DateTime.now().toIso8601String().substring(0, 10);
      final employees = await _employeeRepository.getEmployees();
      final config = await _employeeRepository.getPayrollConfig();
      final attendance = await _employeeRepository.getAttendanceForDate(date);
      
      emit(EmployeesLoaded(
        employees: employees,
        attendanceRecords: attendance,
        selectedDate: date,
        config: config,
      ));
    } catch (e) {
      emit(EmployeesError(e.toString()));
    }
  }

  Future<void> _onLoadAttendanceForDate(
      LoadAttendanceForDateEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        final attendance =
            await _employeeRepository.getAttendanceForDate(event.date);
        emit(currentState.copyWith(
          attendanceRecords: attendance,
          selectedDate: event.date,
        ));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onAddEmployee(
      AddEmployeeEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        await _employeeRepository.addEmployee(event.employee);
        add(LoadEmployeesData(initialDate: currentState.selectedDate));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateEmployee(
      UpdateEmployeeEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        await _employeeRepository.updateEmployee(event.employee);
        add(LoadEmployeesData(initialDate: currentState.selectedDate));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteEmployee(
      DeleteEmployeeEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        await _employeeRepository.deleteEmployee(event.id);
        add(LoadEmployeesData(initialDate: currentState.selectedDate));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onSaveAttendanceRecord(
      SaveAttendanceRecordEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        await _employeeRepository.saveAttendanceRecord(event.record);
        // Refresh the attendance records list for current date
        final attendance = await _employeeRepository
            .getAttendanceForDate(currentState.selectedDate);
        emit(currentState.copyWith(attendanceRecords: attendance));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onSavePayrollConfig(
      SavePayrollConfigEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        await _employeeRepository.savePayrollConfig(event.config);
        emit(currentState.copyWith(config: event.config));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }

  Future<void> _onCalculateWeeklyPayroll(
      CalculateWeeklyPayrollEvent event, Emitter<EmployeesState> emit) async {
    final currentState = state;
    if (currentState is EmployeesLoaded) {
      try {
        final Map<String, List<AttendanceRecord>> weeklyMap = {};
        for (var emp in currentState.employees) {
          final list = await _employeeRepository
              .getAttendanceForEmployeeInPeriod(emp.id, event.startDate, event.endDate);
          weeklyMap[emp.id] = list;
        }
        emit(currentState.copyWith(
          weeklyAttendance: weeklyMap,
          payrollStartDate: event.startDate,
          payrollEndDate: event.endDate,
        ));
      } catch (e) {
        emit(EmployeesError(e.toString()));
      }
    }
  }
}
