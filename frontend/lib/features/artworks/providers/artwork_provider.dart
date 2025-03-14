import 'package:flutter/foundation.dart';
import '../services/artwork_service.dart';
import '../models/artwork_model.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class ArtworkProvider with ChangeNotifier {
  final ArtworkService _artworkService;
  final Dio _dio;
  List<Artwork> _artworks = [];
  List<Artwork> _userArtworks = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  List<Artwork> _unlockedArtworks = [];

  ArtworkProvider(this._artworkService, this._dio);

  ArtworkService get artworkService => _artworkService;

  List<Artwork> get artworks => _artworks;
  List<Artwork> get userArtworks => _userArtworks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Artwork> get unlockedArtworks => _unlockedArtworks;

  Future<void> init() async {
    await Future.wait([
      fetchNearbyArtworks(_currentPosition?.latitude ?? 0, _currentPosition?.longitude ?? 0),
      fetchUserArtworks(),
      fetchUnlockedArtworks(),
    ]);
  }

  Future<void> fetchNearbyArtworks(double latitude, double longitude) async {
    try {
      _isLoading = true;
      notifyListeners();

      _artworks = await _artworkService.getNearbyArtworks(latitude, longitude);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error getting nearby artworks: $e');
      throw e;
    }
  }

  Future<void> fetchUserArtworks() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _dio.get('/artworks/user/artworks');
      if (response.statusCode == 200) {
        _userArtworks = (response.data as List)
            .map((json) => Artwork.fromJson(json))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching user artworks: $e');
      throw e;
    }
  }

  Future<void> unlockArtwork(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _artworkService.unlockArtwork(id);
      if (success) {
        // Update the unlocked status in nearby artworks
        final index = _artworks.indexWhere((a) => a.id == id);
        if (index != -1) {
          _artworks[index] = _artworks[index].copyWith(isUnlocked: true);
        }
        
        // Fetch the updated unlocked artworks
        await fetchUnlockedArtworks();
      }
    } catch (e) {
      _error = e.toString();
      print('Error unlocking artwork: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addArtwork(FormData formData, String artistName) async {
    try {
      final response = await _artworkService.createArtwork(formData);
      if (response != null) {
        // Refresh the artworks list
        await fetchNearbyArtworks(
          double.parse(formData.fields.firstWhere((f) => f.key == 'latitude').value),
          double.parse(formData.fields.firstWhere((f) => f.key == 'longitude').value),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error in addArtwork: $e');
      rethrow;
    }
  }

  Future<void> refreshArtworks() async {
    if (_currentPosition != null) {
      await fetchNearbyArtworks(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  Future<void> updateCurrentPosition(Position position) async {
    _currentPosition = position;
    await fetchNearbyArtworks(position.latitude, position.longitude);
  }

  Future<List<ArtworkCategory>> getCategories() async {
    try {
      return await _artworkService.getCategories();
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  Future<void> deleteArtwork(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _artworkService.deleteArtwork(id);
      
      // Remove from local list
      _artworks.removeWhere((artwork) => artwork.id == id);
      
      // Refresh the artworks list
      if (_currentPosition != null) {
        await fetchNearbyArtworks(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
      
    } catch (e) {
      _error = e.toString();
      print('Error in deleteArtwork: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnlockedArtworks() async {
    try {
      _error = null;
      final artworks = await _artworkService.getUnlockedArtworks();
      _unlockedArtworks = artworks;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error fetching unlocked artworks: $_error');
      rethrow;
    }
  }
} 