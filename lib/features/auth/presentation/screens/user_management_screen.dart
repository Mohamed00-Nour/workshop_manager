import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const UserManagementScreen({super.key, required this.authRepository});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<UserModel>> _usersFuture;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = widget.authRepository.getAllUsers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.authRepository.addEmployeeUser(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      Navigator.pop(context);
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _refreshUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.translate('success')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.translate('add_employee')),
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: context.translate('email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? context.translate('required_field')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: context.translate('password'),
                          prefixIcon: const Icon(Icons.lock_outlined),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
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
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          setDialogState(() => _isLoading = true);
                          await _addEmployee();
                          setDialogState(() => _isLoading = false);
                        },
                        child: Text(context.translate('save')),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('confirm_delete')),
        content: Text(context.translate('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.authRepository.deleteUser(uid);
        _refreshUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDark ? const Color(0xFF46F0D2) : const Color(0xFF0D9488);

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.translate('users'),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF131321),
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : const Color(0xFF131321),
          ),
        ),
        body: FutureBuilder<List<UserModel>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: accent));
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70)),
                    const SizedBox(height: 12),
                    Text(context.translate('no_data'), style: TextStyle(color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70))),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isAdmin = user.role == 'admin';

                return Card(
                  color: isDark ? const Color(0xFF1D1D30) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? const Color(0xFF2C2C45) : const Color(0xFFE2E8F0)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isAdmin ? Colors.amber.withAlpha(30) : accent.withAlpha(30),
                      foregroundColor: isAdmin ? Colors.amber : accent,
                      child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.engineering),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${user.email} (${context.translate(user.role)})',
                      style: TextStyle(color: isDark ? const Color(0xFF9090A0) : const Color(0xFF5D5D70)),
                    ),
                    trailing: isAdmin
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteUser(user.uid),
                          ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: accent,
          foregroundColor: isDark ? const Color(0xFF131321) : Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
