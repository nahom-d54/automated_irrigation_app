import 'package:irrigation_app/data/datasources/auth_data_source.dart';
import 'package:irrigation_app/data/models/auth_models.dart';
import 'package:irrigation_app/domain/entities/user.dart';
import 'package:irrigation_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource authDataSource;

  AuthRepositoryImpl({required this.authDataSource});

  @override
  Future<User> login(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
     await authDataSource.login(request);
    return await authDataSource.getCurrentUser();
  }

  @override
  Future<User> register(String email, String password, String firstName, String lastName) async {
    final request = RegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    return await authDataSource.register(request);
  }

  @override
  Future<User> getCurrentUser() async {
    return await authDataSource.getCurrentUser();
  }

  @override
  Future<void> logout() async {
    await authDataSource.logout();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await authDataSource.isLoggedIn();
  }

  @override
  Future<User?> getStoredUser() async {
    return await authDataSource.getStoredUser();
  }

  @override
  Future<void> refreshToken() async {
    await authDataSource.refreshToken();
  }
}
