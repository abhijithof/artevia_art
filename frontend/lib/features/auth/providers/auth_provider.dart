import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _token = await AuthService.login(email, password);
      print('Login successful, token: $_token');
      
      _user = await _authService.getCurrentUser(_token!);
      await _saveToken(_token!);
      _isLoading = false;
      _error = null;  // Clear any previous errors
      notifyListeners();
    } catch (e) {
      print('Error in login: $e');
      _token = null;
      _user = null;
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      await _removeToken();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String email, String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(email, username, password);
      await login(email, password);  // Auto login after registration
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      try {
        _user = await _authService.getCurrentUser(_token!);
        notifyListeners();
      } catch (e) {
        _token = null;
        _user = null;
        await _removeToken();
        notifyListeners();
      }
    }
  }
} 