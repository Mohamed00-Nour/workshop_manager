import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const LoginScreen({
    super.key,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        context.read<AuthBloc>().add(
              LoginRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            );
      } else {
        context.read<AuthBloc>().add(
              RegisterRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.engineering,
            size: 64,
            color: primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _isLogin ? context.translate('welcome_back') : context.translate('register'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin ? context.translate('please_login') : "",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: _isLogin ? 32 : 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.translate('email'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.translate('required_field');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.translate('password'),
              prefixIcon: const Icon(Icons.lock_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.translate('required_field');
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? context.translate('login') : context.translate('register')),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              _isLogin
                  ? context.translate('dont_have_account')
                  : context.translate('already_have_account'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeChanged(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          // Language Selector
          TextButton.icon(
            icon: const Icon(Icons.translate),
            label: Text(context.translate('language')),
            onPressed: () {
              final newLocale = Localizations.localeOf(context).languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar');
              widget.onLanguageChanged(newLocale);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF131321), Color(0xFF1F1F35), Color(0xFF131321)],
                )
              : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ResponsiveLayout(
              mobile: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: formContent,
                ),
              ),
              tablet: SizedBox(
                width: 480,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: formContent,
                  ),
                ),
              ),
              desktop: SizedBox(
                width: 520,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: formContent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
