import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _nearbyArtworks = [];
  Set<int> _discoveredArtworks = {};
  bool _isLoading = false;
  String? _error;

  ArtworkProvider(this._artworkService);

  List<Artwork> get nearbyArtworks => _nearbyArtworks;
  Set<int> get discoveredArtworks => _discoveredArtworks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNearbyArtworks(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _nearbyArtworks = await _artworkService.getNearbyArtworks(latitude, longitude);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
} 