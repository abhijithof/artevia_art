import 'package:flutter/foundation.dart';
import '../services/artwork_service.dart';
import '../models/artwork_model.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _artworks = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;

  ArtworkProvider(this._artworkService);

  List<Artwork> get artworks => _artworks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNearbyArtworks(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final artworks = await _artworkService.getNearbyArtworks(latitude, longitude);
      _artworks = artworks;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unlockArtwork(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _artworkService.unlockArtwork(id);
      if (success) {
        // Update the artwork in the list
        final artwork = await _artworkService.getArtworkDetails(id);
        final index = _artworks.indexWhere((a) => a.id == id);
        if (index != -1) {
          _artworks[index] = artwork;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addArtwork({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _artworkService.createArtwork(
        title: title,
        description: description,
        imageFile: imageFile,
        latitude: latitude,
        longitude: longitude,
      );

      // Refresh nearby artworks
      await fetchNearbyArtworks(latitude, longitude);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
} 