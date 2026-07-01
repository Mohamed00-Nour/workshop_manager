import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/notification_helper.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        await NotificationHelper().saveUserToken(user.uid);
        emit(Authenticated(user));
      } else {
        final cache = CacheService();
        final email = cache.getSavedEmail();
        final password = cache.getSavedPassword();
        if (email != null && password != null) {
          try {
            final loggedInUser = await _authRepository.login(email, password);
            if (loggedInUser != null) {
              await NotificationHelper().saveUserToken(loggedInUser.uid);
              emit(Authenticated(loggedInUser));
              return;
            }
          } catch (e) {
            // Attempt offline fallback with cached user profile
            final cachedUser = await _authRepository.getCachedUser();
            if (cachedUser != null && cachedUser.email == email) {
              emit(Authenticated(cachedUser));
              return;
            }
            // If no match or cache empty, emit unauthenticated or error
            emit(Unauthenticated());
            return;
          }
        }
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      if (user != null) {
        final cache = CacheService();
        await cache.saveCredentials(event.email, event.password);
        await NotificationHelper().saveUserToken(user.uid);
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Login failed: User record not found.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(event.email, event.password);
      if (user != null) {
        final cache = CacheService();
        await cache.saveCredentials(event.email, event.password);
        await NotificationHelper().saveUserToken(user.uid);
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Registration failed: User record could not be created.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      final cache = CacheService();
      await cache.clearCredentials();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
