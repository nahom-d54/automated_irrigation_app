import 'package:irrigation_app/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String firstName, String lastName);
  Future<User> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getStoredUser();
  Future<void> refreshToken();
}
