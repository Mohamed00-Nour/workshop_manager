import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/client_model.dart';

class AddClientDialog extends StatefulWidget {
  final ClientModel? client; // If editing
  final Function(ClientModel) onSave;

  const AddClientDialog({super.key, this.client, required this.onSave});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _companyController = TextEditingController(text: widget.client?.company ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final client = ClientModel(
        id: widget.client?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        totalJobsCost: widget.client?.totalJobsCost ?? 0.0,
        totalPaidAmount: widget.client?.totalPaidAmount ?? 0.0,
        currentBalance: widget.client?.currentBalance ?? 0.0,
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onSave(client);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.client == null
            ? context.translate('add_client')
            : context.translate('edit_client'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.translate('client_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? context.translate('required_field')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.translate('phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? context.translate('required_field')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: context.translate('company'),
                  prefixIcon: const Icon(Icons.business_outlined),
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
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.translate('save')),
        ),
      ],
    );
  }
}
