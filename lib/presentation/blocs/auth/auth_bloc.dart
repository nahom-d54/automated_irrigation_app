import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/domain/entities/user.dart';
import 'package:irrigation_app/domain/repositories/auth_repository.dart';
import 'package:irrigation_app/data/datasources/auth_data_source.dart';
import 'package:irrigation_app/data/datasources/sensor_data_socketio_source.dart';
part 'auth_state.dart';
part 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final AuthDataSource authDataSource;
  final SensorDataSocketIOSource socket;

  AuthBloc(
      {required this.authDataSource,
      required this.authRepository,
      required this.socket})
      : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthRefreshRequested>(_onAuthRefreshRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await authRepository.getStoredUser();
        final token = await authDataSource.getAccessToken();
        if (token != null && token.isNotEmpty && user != null) {
          // If token is not available, consider user unauthenticated
          await socket.connect();
          emit(AuthAuthenticated(user: user));
          return;
        } else {
          // Try to get fresh user data
          try {
            final freshUser = await authRepository.getCurrentUser();
            emit(AuthAuthenticated(user: freshUser));
          } catch (e) {
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // final times = DateTime.now();
      // final user = User(
      //   id: "20",
      //   email: 'firaol@gmail.com',
      //   firstName: 'Me',
      //   lastName: 'you',
      //   role: UserRole.operator,
      //   isActive: true,
      //   createdAt: times
      // );
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Invalid Credential!'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(
        event.email,
        event.password,
        event.firstName,
        event.lastName,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Registration failed, Please try agin!'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails, consider user logged out locally
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // await authRepository.refreshToken();
      final user = await authRepository.getCurrentUser();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}
