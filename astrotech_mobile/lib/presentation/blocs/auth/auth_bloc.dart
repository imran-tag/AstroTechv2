import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/datasources/local/local_database.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_user.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final Technician? technician;

  const Authenticated({required this.user, this.technician});

  @override
  List<Object?> get props => [user, technician];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final FlutterSecureStorage secureStorage;
  final LocalDatabase localDatabase;

  AuthBloc({
    required this.loginUser,
    required this.secureStorage,
    required this.localDatabase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final token = await secureStorage.read(key: ApiConstants.tokenKey);

      if (token != null && token.isNotEmpty) {
        // Try to get stored user data
        final userData = await secureStorage.read(key: ApiConstants.userKey);
        if (userData != null) {
          // We have a valid session
          emit(Authenticated(
            user: User(id: 0, email: 'cached'),
          ));
          return;
        }
      }

      emit(Unauthenticated());
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Clear local cache on login to avoid seeing other people's data
      await localDatabase.clearAll();

      final result = await loginUser(event.email, event.password);

      emit(Authenticated(
        user: result.user,
        technician: result.technician,
      ));
    } catch (e) {
      final err = e.toString();
      String message;

      if (err.contains('401') || err.contains('403')) {
        message = 'Email ou mot de passe incorrect';
      } else if (err.contains('refused') || err.contains('SocketException')) {
        message = 'Impossible de contacter le serveur.\nVérifiez que vous êtes sur le même réseau Wi-Fi que le serveur.';
      } else if (err.contains('timeout') || err.contains('TimeoutException')) {
        message = 'La connexion a expiré. Vérifiez votre réseau et réessayez.';
      } else if (err.contains('Connection') || err.contains('network')) {
        message = 'Erreur réseau. Vérifiez votre connexion internet.';
      } else {
        message = 'Une erreur est survenue. Réessayez.';
      }

      emit(AuthError(message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await localDatabase.clearAll();
      await secureStorage.deleteAll();
      emit(Unauthenticated());
    } catch (e) {
      emit(Unauthenticated());
    }
  }
}