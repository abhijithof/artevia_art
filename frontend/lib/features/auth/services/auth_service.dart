import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio;
  final String? authToken;

  AuthService(this._dio, {this.authToken});

  // Add a method to create an authenticated instance
  AuthService withToken(String token) {
    return AuthService(_dio, authToken: token);
  }

  Future<String> login(String email, String password) async {
    try {
      print('Attempting login for: $email');
      final response = await _dio.post(
        '/auth/token',
        data: {
          'username': email,  // FastAPI OAuth2 expects 'username'
          'password': password,
          'grant_type': 'password',  // Add this for OAuth2
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',  // Required for OAuth2
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      print('Login response: ${response.data}');
      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        if (token == null) {
          throw Exception('No token in response');
        }
        return token;
      }
      throw Exception('Failed to login: ${response.statusCode}');
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  Future<void> register(String email, String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to register');
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      print('Getting current user with token: $authToken');
      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );

      print('Current user response: ${response.data}');
      print('DEBUG - User role from backend: ${response.data['role']}');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw Exception('Failed to get user profile: ${response.statusCode}');
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<User> convertToArtist() async {
    try {
      final response = await _dio.put(
        '/users/me/role/artist',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Convert to artist response: ${response.data}');
      if (response.statusCode == 200) {
        return await getCurrentUser();
      }
      throw Exception('Failed to convert to artist: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('Error converting to artist: $e');
      rethrow;
    }
  }
} 