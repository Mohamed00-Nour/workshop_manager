import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/attendance_model.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';
import 'payroll_config_dialog.dart';

class EmployeesDashboardScreen extends StatefulWidget {
  const EmployeesDashboardScreen({super.key});

  @override
  State<EmployeesDashboardScreen> createState() => _EmployeesDashboardScreenState();
}

class _EmployeesDashboardScreenState extends State<EmployeesDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EmployeesBloc _bloc;
  
  // Date tracking for attendance logger
  DateTime _selectedAttendanceDate = DateTime.now();
  
  // Date range tracking for payroll report
  DateTime _payrollStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _payrollEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bloc = EmployeesBloc(EmployeeRepository())..add(LoadEmployeesData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  void _showAddEditEmployeeDialog({EmployeeModel? employee}) {
    final nameController = TextEditingController(text: employee?.name ?? '');
    final phoneController = TextEditingController(text: employee?.phone ?? '');
    final salaryController = TextEditingController(text: employee?.baseWeeklySalary.toString() ?? '');
    final hoursController = TextEditingController(text: employee?.standardHoursPerDay.toString() ?? '8.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1D1D30) : Colors.white,
          title: Text(
            employee == null ? context.translate('add_employee') : context.translate('edit_employee'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: context.translate('client_name')),
                    validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: context.translate('phone')),
                    validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: salaryController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '${context.translate('weekly_salary')} (${context.translate('currency')})'),
                    validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: context.translate('working_hours_day')),
                    validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.translate('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final emp = EmployeeModel(
                    id: employee?.id ?? '',
                    name: nameController.text,
                    phone: phoneController.text,
                    baseWeeklySalary: double.parse(salaryController.text),
                    standardHoursPerDay: double.parse(hoursController.text),
                    createdAt: employee?.createdAt ?? DateTime.now(),
                  );
                  if (employee == null) {
                    _bloc.add(AddEmployeeEvent(emp));
                  } else {
                    _bloc.add(UpdateEmployeeEvent(emp));
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488),
                foregroundColor: isDark ? const Color(0xFF131321) : Colors.white,
              ),
              child: Text(context.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _showAttendanceLoggerOverlay(EmployeeModel employee, AttendanceRecord? record) {
    final isAbsent = ValueNotifier<bool>(record?.isAbsent ?? false);
    final lateController = TextEditingController(text: record?.lateMinutes.toString() ?? '0');
    final overtimeController = TextEditingController(text: record?.overtimeMinutes.toString() ?? '0');
    final notesController = TextEditingController(text: record?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1D1D30) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.translate('attendance')}: ${employee.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isAbsent,
                builder: (context, absent, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.translate('present'), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Switch(
                            value: !absent,
                            activeColor: isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488),
                            onChanged: (val) {
                              isAbsent.value = !val;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!absent) ...[
                        TextFormField(
                          controller: lateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.translate('late_minutes'),
                            prefixIcon: const Icon(Icons.watch_later_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: overtimeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '${context.translate('overtime')} (${context.translate('late_minutes')})',
                            prefixIcon: const Icon(Icons.add_circle_outline),
                            helperText: context.translate('enter_overtime_minutes'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: context.translate('notes'),
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newRecord = AttendanceRecord(
                      id: record?.id ?? '',
                      employeeId: employee.id,
                      date: _formatDate(_selectedAttendanceDate),
                      isAbsent: isAbsent.value,
                      lateMinutes: isAbsent.value ? 0 : int.tryParse(lateController.text) ?? 0,
                      overtimeMinutes: isAbsent.value ? 0 : int.tryParse(overtimeController.text) ?? 0,
                      notes: notesController.text,
                    );
                    _bloc.add(SaveAttendanceRecordEvent(newRecord));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488),
                    foregroundColor: isDark ? const Color(0xFF131321) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(context.translate('save')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488);
    final Color cardBg = isDark ? const Color(0xFF1D1D30) : Colors.white;
    final Color subtleText = isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70);
    final Color dividerColor = isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0);

    return BlocProvider.value(
      value: _bloc,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF131321), Color(0xFF1F1F35), Color(0xFF131321)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7F7FA), Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
                ),
        ),
        child: BlocBuilder<EmployeesBloc, EmployeesState>(
          builder: (context, state) {
            if (state is EmployeesLoading) {
              return const Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is EmployeesError) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
              );
            }
            if (state is EmployeesLoaded) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF131321)),
                  title: Text(
                    context.translate('employees'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF131321),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => PayrollConfigDialog(
                            config: state.config,
                            onSave: (config) {
                              _bloc.add(SavePayrollConfigEvent(config));
                            },
                          ),
                        );
                      },
                      tooltip: context.translate('settings_attendance'),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dividerColor),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: accent,
                        unselectedLabelColor: subtleText,
                        indicator: BoxDecoration(
                          color: accent.withAlpha(isDark ? 30 : 18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.badge_outlined, size: 16),
                                const SizedBox(width: 6),
                                Text(context.translate('employees'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16),
                                const SizedBox(width: 6),
                                Text(context.translate('attendance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.monetization_on_outlined, size: 16),
                                const SizedBox(width: 6),
                                Text(context.translate('payroll'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Employees List
                          _buildEmployeesTab(context, state, cardBg, dividerColor, subtleText, accent, isDark),
                          // Tab 2: Attendance Tracker
                          _buildAttendanceTab(context, state, cardBg, dividerColor, subtleText, accent, isDark),
                          // Tab 3: Payroll Calculator
                          _buildPayrollTab(context, state, cardBg, dividerColor, subtleText, accent),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // --- TAB 1: Employees ---
  Widget _buildEmployeesTab(
    BuildContext context,
    EmployeesLoaded state,
    Color cardBg,
    Color dividerColor,
    Color subtleText,
    Color accent,
    bool isDark,
  ) {
    if (state.employees.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, size: 64, color: subtleText),
              const SizedBox(height: 12),
              Text(context.translate('no_employees'), style: TextStyle(color: subtleText)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditEmployeeDialog(),
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        itemCount: state.employees.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final emp = state.employees[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Colored icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_outline, color: accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Name & details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF131321),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 12, color: subtleText),
                            const SizedBox(width: 4),
                            Text(emp.phone, style: TextStyle(fontSize: 12, color: subtleText)),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_outlined, size: 12, color: subtleText),
                            const SizedBox(width: 4),
                            Text('${emp.standardHoursPerDay}h/day', style: TextStyle(fontSize: 12, color: subtleText)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(isDark ? 30 : 15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${emp.baseWeeklySalary} ${context.translate('currency')} / ${context.translate('weekly_salary')}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(isDark ? 30 : 15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                          onPressed: () => _showAddEditEmployeeDialog(employee: emp),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(isDark ? 30 : 15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1D1D30) : Colors.white,
                                title: Text(context.translate('delete')),
                                content: Text(context.translate('confirm_delete')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(context.translate('cancel')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _bloc.add(DeleteEmployeeEvent(emp.id));
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: Text(context.translate('delete')),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditEmployeeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- TAB 2: Attendance Tracker ---
  Widget _buildAttendanceTab(
    BuildContext context,
    EmployeesLoaded state,
    Color cardBg,
    Color dividerColor,
    Color subtleText,
    Color accent,
    bool isDark,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return Column(
      children: [
        // Date selector bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: () {
                  setState(() {
                    _selectedAttendanceDate = _selectedAttendanceDate.subtract(const Duration(days: 1));
                  });
                  _bloc.add(LoadAttendanceForDateEvent(_formatDate(_selectedAttendanceDate)));
                },
              ),
              GestureDetector(
                onTap: () async {
                  final pick = await showDatePicker(
                    context: context,
                    initialDate: _selectedAttendanceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pick != null) {
                    setState(() {
                      _selectedAttendanceDate = pick;
                    });
                    _bloc.add(LoadAttendanceForDateEvent(_formatDate(_selectedAttendanceDate)));
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(_selectedAttendanceDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  setState(() {
                    _selectedAttendanceDate = _selectedAttendanceDate.add(const Duration(days: 1));
                  });
                  _bloc.add(LoadAttendanceForDateEvent(_formatDate(_selectedAttendanceDate)));
                },
              ),
            ],
          ),
        ),
        
        Expanded(
          child: state.employees.isEmpty
              ? Center(child: Text(context.translate('no_employees'), style: TextStyle(color: subtleText)))
              : ListView.builder(
                  itemCount: state.employees.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final emp = state.employees[index];
                    // Find attendance record if exists
                    final record = state.attendanceRecords.firstWhere(
                      (r) => r.employeeId == emp.id,
                      orElse: () => AttendanceRecord(
                        id: '',
                        employeeId: emp.id,
                        date: _formatDate(_selectedAttendanceDate),
                        isAbsent: false,
                        lateMinutes: 0,
                        overtimeMinutes: 0,
                      ),
                    );

                    final statusColor = record.isAbsent ? Colors.red : Colors.green;
                    final statusIcon = record.isAbsent ? Icons.cancel_outlined : Icons.check_circle_outline;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 80 : 12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Status icon container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(isDark ? 35 : 20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(statusIcon, color: statusColor, size: 24),
                            ),
                            const SizedBox(width: 14),
                            // Name & badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF131321),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _attendanceBadge(
                                        record.isAbsent ? context.translate('absent') : context.translate('present'),
                                        statusColor,
                                        isDark,
                                      ),
                                      if (!record.isAbsent) ...[
                                        _attendanceBadge(
                                          '${context.translate('late_minutes')}: ${record.lateMinutes}',
                                          Colors.orange,
                                          isDark,
                                        ),
                                        _attendanceBadge(
                                          '${context.translate('overtime')}: ${record.overtimeMinutes}',
                                          accent,
                                          isDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: accent.withAlpha(isDark ? 30 : 15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.edit_note_outlined, color: accent, size: 20),
                                onPressed: () => _showAttendanceLoggerOverlay(emp, record),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 3: Payroll Calculator ---
  Widget _buildPayrollTab(
    BuildContext context,
    EmployeesLoaded state,
    Color cardBg,
    Color dividerColor,
    Color subtleText,
    Color accent,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return Column(
      children: [
        // Date range select
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: _payrollStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pick != null) {
                          setState(() {
                            _payrollStartDate = pick;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(dateFormat.format(_payrollStartDate)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(context.translate('to')),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pick = await showDatePicker(
                          context: context,
                          initialDate: _payrollEndDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pick != null) {
                          setState(() {
                            _payrollEndDate = pick;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(dateFormat.format(_payrollEndDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _bloc.add(CalculateWeeklyPayrollEvent(
                      startDate: _formatDate(_payrollStartDate),
                      endDate: _formatDate(_payrollEndDate),
                    ));
                  },
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(context.translate('calculate_payroll')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131321) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: state.weeklyAttendance.isEmpty
              ? Center(child: Text(context.translate('select_range_payroll'), style: TextStyle(color: subtleText)))
              : ListView.builder(
                  itemCount: state.employees.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final emp = state.employees[index];
                    final records = state.weeklyAttendance[emp.id] ?? [];
                    
                    // Net salary calculation
                    int totalLateMinutes = 0;
                    int totalOvertimeMinutes = 0;
                    int daysWorked = 0;
                    int daysAbsent = 0;

                    for (var r in records) {
                      if (r.isAbsent) {
                        daysAbsent++;
                      } else {
                        daysWorked++;
                        totalLateMinutes += r.lateMinutes;
                        totalOvertimeMinutes += r.overtimeMinutes;
                      }
                    }

                    // Calculations
                    final double totalOvertimeHours = totalOvertimeMinutes / 60.0;
                    final double totalLateHours = totalLateMinutes / 60.0;
                    
                    // Deductible delay calculation based on daily threshold
                    double deductibleLateHours = 0.0;
                    final double allowedGraceHours = state.config.graceMinutes / 60.0;
                    if (totalLateHours > allowedGraceHours) {
                      deductibleLateHours = totalLateHours - allowedGraceHours;
                    }

                    final double overtimePay = totalOvertimeHours * state.config.overtimeHourlyRate;
                    final double lateDeduction = deductibleLateHours * state.config.lateDeductionHourlyRate;
                    final double netSalary = emp.baseWeeklySalary + overtimePay - lateDeduction;

                    return Card(
                      color: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: dividerColor),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${netSalary.toStringAsFixed(2)} ${context.translate('currency')}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(color: dividerColor),
                            const SizedBox(height: 8),
                            _payrollInfoRow(context, 'base_salary', '${emp.baseWeeklySalary} ${context.translate('currency')}', subtleText),
                            _payrollInfoRow(context, 'present', '$daysWorked ${context.translate('days')}', subtleText),
                            _payrollInfoRow(context, 'absent', '$daysAbsent ${context.translate('days')}', subtleText),
                            _payrollInfoRow(context, 'late_minutes', '$totalLateMinutes ${context.translate('mins')} (${deductibleLateHours.toStringAsFixed(1)} ${context.translate('hrs')} ${context.translate('deductible')})', subtleText),
                            _payrollInfoRow(context, 'overtime', '$totalOvertimeMinutes ${context.translate('mins')} (${totalOvertimeHours.toStringAsFixed(1)} ${context.translate('hrs')})', subtleText),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${context.translate('deductions')}: -${lateDeduction.toStringAsFixed(1)}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                                Text('${context.translate('additions')}: +${overtimePay.toStringAsFixed(1)}', style: const TextStyle(color: Colors.green, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _payrollInfoRow(BuildContext context, String key, String val, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.translate(key), style: TextStyle(color: textCol, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _attendanceBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
