import 'package:flutter/foundation.dart';

class ApiService {
  // Use different base URLs for web and mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';  // For Android emulator
    }
  }
  
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // Remove any double slashes and ensure proper URL formatting
    final cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    return '$baseUrl/$cleanPath';
  }
} 