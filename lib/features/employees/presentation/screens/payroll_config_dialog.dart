import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/payroll_config_model.dart';

class PayrollConfigDialog extends StatefulWidget {
  final PayrollConfig config;
  final Function(PayrollConfig) onSave;

  const PayrollConfigDialog({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<PayrollConfigDialog> createState() => _PayrollConfigDialogState();
}

class _PayrollConfigDialogState extends State<PayrollConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _graceController;
  late TextEditingController _overtimeController;
  late TextEditingController _lateController;

  @override
  void initState() {
    super.initState();
    _graceController = TextEditingController(text: widget.config.graceMinutes.toString());
    _overtimeController = TextEditingController(text: widget.config.overtimeHourlyRate.toString());
    _lateController = TextEditingController(text: widget.config.lateDeductionHourlyRate.toString());
  }

  @override
  void dispose() {
    _graceController.dispose();
    _overtimeController.dispose();
    _lateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1D1D30) : Colors.white,
      title: Text(
        context.translate('settings_attendance'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _graceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.translate('grace_minutes'),
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _overtimeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${context.translate('hourly_overtime_rate')} (${context.translate('currency')})',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                ),
                validator: (val) => val == null || val.isEmpty ? context.translate('required_field') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lateController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${context.translate('hourly_deduction_rate')} (${context.translate('currency')})',
                  prefixIcon: const Icon(Icons.remove_circle_outline),
                ),
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
            if (_formKey.currentState!.validate()) {
              final newConfig = PayrollConfig(
                graceMinutes: int.parse(_graceController.text),
                overtimeHourlyRate: double.parse(_overtimeController.text),
                lateDeductionHourlyRate: double.parse(_lateController.text),
              );
              widget.onSave(newConfig);
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
  }
}
