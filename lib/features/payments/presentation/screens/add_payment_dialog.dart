import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/models/payment_model.dart';
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';

class AddPaymentDialog extends StatefulWidget {
  final String clientId;

  const AddPaymentDialog({super.key, required this.clientId});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isSaving = true);

    final payment = PaymentModel(
      id: '',
      clientId: widget.clientId,
      amount: double.parse(_amountController.text.trim()),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
      recordedByUid: authState.user.uid,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    context.read<PaymentsBloc>().add(AddPaymentRequested(payment));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.translate('add_payment')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.translate('amount'),
                  suffixText: context.translate('currency'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('required_field');
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: context.translate('payment_method'),
                ),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(context.translate('cash'))),
                  DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text(context.translate('bank_transfer'))),
                  DropdownMenuItem(value: 'check', child: Text(context.translate('check'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _paymentMethod = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: context.translate('notes'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.translate('cancel')),
        ),
        _isSaving
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _submit,
                child: Text(context.translate('save')),
              ),
      ],
    );
  }
}
