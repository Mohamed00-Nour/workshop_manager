import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_helper.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/clients/data/repositories/client_repository.dart';
import 'features/clients/presentation/bloc/clients_bloc.dart';
import 'features/clients/presentation/screens/clients_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (using local platform config files)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize Local Database cache
  final cacheService = CacheService();
  await cacheService.init();

  // Initialize notification tokens and check permissions
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;
  late ThemeMode _themeMode;
  final CacheService _cacheService = CacheService();
  final AuthRepository _authRepository = AuthRepository();
  final ClientRepository _clientRepository = ClientRepository();

  @override
  void initState() {
    super.initState();
    // Load cached preferences or defaults
    _locale = Locale(_cacheService.getLanguage());
    
    final savedTheme = _cacheService.getThemeMode();
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _cacheService.setLanguage(locale.languageCode);
  }

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    _cacheService.setThemeMode(themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(_authRepository)..add(CheckAuthStatus()),
        ),
        BlocProvider<ClientsBloc>(
          create: (context) => ClientsBloc(_clientRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Workshop Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is Authenticated) {
              return ClientsListScreen(
                currentUser: state.user,
                onLanguageChanged: _changeLanguage,
                onThemeChanged: _changeTheme,
                authRepository: _authRepository,
              );
            }
            return LoginScreen(
              onLanguageChanged: _changeLanguage,
              onThemeChanged: _changeTheme,
              currentThemeMode: _themeMode,
            );
          },
        ),
      ),
    );
  }
}
