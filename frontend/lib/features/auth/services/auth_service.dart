import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',  // Make sure this matches your backend port
    validateStatus: (status) => true,  // For debugging
  ));

  Future<String> login(String email, String password) async {
    try {
      print('Attempting login for: $email'); // Debug print

      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });

      print('Sending login request...'); // Debug print
      final response = await _dio.post(
        '/auth/token',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );
      print('Login response: ${response.data}'); // Debug print

      if (response.statusCode == 200) {
        return response.data['access_token'];
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Login error: $e'); // Debug print
      rethrow;
    }
  }

  Future<User> register(String email, String username, String password) async {
    try {
      print('Attempting registration...'); // Debug print
      final response = await _dio.post(
        '/users/',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );
      print('Registration response: ${response.data}'); // Debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Registration error: $e'); // Debug print
      rethrow;
    }
  }

  Future<User> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      print('Get user error: $e'); // Debug print
      rethrow;
    }
  }
} 