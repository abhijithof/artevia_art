import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../artworks/providers/artwork_provider.dart';
import 'package:geolocator/geolocator.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService);

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isArtist => _user?.role == 'artist';

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Starting login process for: $email');
      _token = await _authService.login(email, password);
      print('Login successful, token: $_token');
      
      final authenticatedService = _authService.withToken(_token!);
      _user = await authenticatedService.getCurrentUser();
      print('User fetched successfully: ${_user?.username}');
      
      await _saveToken(_token!);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error in login process: $e');
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
    _removeToken();
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
        final authenticatedService = _authService.withToken(_token!);
        _user = await authenticatedService.getCurrentUser();
        notifyListeners();
      } catch (e) {
        _token = null;
        _user = null;
        await _removeToken();
        notifyListeners();
      }
    }
  }

  Future<void> convertToArtist() async {
    try {
      _isLoading = true;
      notifyListeners();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final authenticatedService = _authService.withToken(_token!);
      _user = await authenticatedService.convertToArtist();
      
      if (_user?.isArtist ?? false) {
        if (navigatorKey.currentContext != null) {
          final artworkProvider = Provider.of<ArtworkProvider>(
            navigatorKey.currentContext!,
            listen: false,
          );
          await artworkProvider.fetchNearbyArtworks(
            position.latitude,
            position.longitude,
          );
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
} 