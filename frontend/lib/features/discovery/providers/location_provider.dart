import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      _currentPosition = position;
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 