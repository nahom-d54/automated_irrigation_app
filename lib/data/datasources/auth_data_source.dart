import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:irrigation_app/data/models/auth_models.dart';
import 'package:irrigation_app/data/models/user_model.dart';

class AuthDataSource {
  final String baseUrl;
  final http.Client httpClient;
  final FlutterSecureStorage secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  AuthDataSource({
    this.baseUrl = 'https://integrated.ai.astu.pro.et',
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  }) : httpClient = httpClient ?? http.Client(),
        secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
    

      final response = await httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login request timeout');
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(json.decode(response.body));
        
        // Store tokens securely
        await _storeTokens(loginResponse);
        
        // Store user data
        await secureStorage.write(
          key: _userDataKey,
          value: json.encode(loginResponse.user),
        );
        
        return loginResponse;
      } else {
        throw Exception('Invalid credential');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> register(RegisterRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/register');
      

      final response = await httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Registration request timeout');
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = json.decode(response.body);
        return UserModel.fromJson(userData);
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final uri = Uri.parse('$baseUrl/api/auth/me');
      
      final response = await httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Get user request timeout');
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final user = UserModel.fromJson(userData['user'] ?? userData);
        
        // Update stored user data
        await secureStorage.write(
          key: _userDataKey,
          value: json.encode(userData['user'] ?? userData),
        );
        
        return user;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await refreshToken();
        return getCurrentUser(); // Retry with new token
      } else {
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        throw Exception('No refresh token found');
      }

      final uri = Uri.parse('$baseUrl/api/auth/refresh');
      
      final response = await httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'refresh_token': refreshTokenValue,
        }),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(json.decode(response.body));
        await _storeTokens(loginResponse);
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      await logout(); // Clear invalid tokens
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      
      if (token != null) {
        final uri = Uri.parse('$baseUrl/api/auth/logout');
        
        await httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      print('Logout API error: $e');
      // Continue with local logout even if API call fails
    } finally {
      // Clear all stored data
      await _clearStoredData();
    }
  }

  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: _refreshTokenKey);
  }

  Future<UserModel?> getStoredUser() async {
    try {
      final userDataString = await secureStorage.read(key: _userDataKey);
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Error getting stored user: $e');
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> _storeTokens(LoginResponse loginResponse) async {
    await secureStorage.write(
      key: _accessTokenKey,
      value: loginResponse.accessToken,
    );
    await secureStorage.write(
      key: _refreshTokenKey,
      value: loginResponse.refreshToken,
    );
  }

  Future<void> _clearStoredData() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _userDataKey);
  }

  void dispose() {
    httpClient.close();
  }
}
