import 'package:flutter/foundation.dart';
import '../services/artwork_service.dart';
import '../models/artwork_model.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _artworks = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  List<Artwork> _unlockedArtworks = [];

  ArtworkProvider(this._artworkService);

  List<Artwork> get artworks => _artworks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Artwork> get unlockedArtworks => _unlockedArtworks;

  Future<void> init() async {
    await Future.wait([
      fetchNearbyArtworks(_currentPosition?.latitude ?? 0, _currentPosition?.longitude ?? 0),
      fetchUnlockedArtworks(),
    ]);
  }

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
        await fetchUnlockedArtworks();
        
        final index = _artworks.indexWhere((a) => a.id == id);
        if (index != -1) {
          _artworks[index] = _artworks[index].copyWith(isUnlocked: true);
        }
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _artworkService.createArtwork(formData, artistName);

      // Force refresh nearby artworks
      if (_currentPosition != null) {
        print('Refreshing nearby artworks after adding new artwork');
        await fetchNearbyArtworks(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Error in addArtwork: $_error');
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

  Future<List<String>> getCategories() async {
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
      _unlockedArtworks = await _artworkService.getUnlockedArtworks();
      notifyListeners();
    } catch (e) {
      print('Error fetching unlocked artworks: $e');
      _error = e.toString();
    }
  }
} 