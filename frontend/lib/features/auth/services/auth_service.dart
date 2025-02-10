import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';

class AuthService {
  static final _dio = Dio(BaseOptions(
    baseUrl: kIsWeb 
        ? 'http://localhost:8000'  // For web
        : 'http://10.0.2.2:8000',  // For Android emulator
    validateStatus: (status) => true,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static Future<String> login(String email, String password) async {
    try {
      print('Attempting login for: $email');
      
      final response = await _dio.post(
        '/auth/token',  // Changed from /auth/login to /auth/token
        data: {
          'username': email,
          'password': password,
          'grant_type': 'password',  // Add this
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',  // Add this
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        return response.data['access_token'];
      }
      
      throw Exception(response.data['detail'] ?? 'Login failed');
    } catch (e) {
      print('Login error: $e');
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