import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _artworks = [];
  Set<int> _discoveredArtworks = {};
  bool _isLoading = false;
  String? _error;

  ArtworkProvider(this._artworkService);

  List<Artwork> get artworks => _artworks;
  Set<int> get discoveredArtworks => _discoveredArtworks;
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

  Future<bool> discoverArtwork(int artworkId) async {
    try {
      final success = await _artworkService.markArtworkAsDiscovered(artworkId);
      if (success) {
        _discoveredArtworks.add(artworkId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isArtworkDiscovered(int artworkId) {
    return _discoveredArtworks.contains(artworkId);
  }

  Future<void> unlockArtwork(int artworkId, double latitude, double longitude) async {
    try {
      await _artworkService.unlockArtwork(artworkId, latitude, longitude);
      
      // Update the local artwork status
      final index = _artworks.indexWhere((a) => a.id == artworkId);
      if (index != -1) {
        _artworks[index].isDiscovered = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error unlocking artwork: $e');
      rethrow;
    }
  }
} 