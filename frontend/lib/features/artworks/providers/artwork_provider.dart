import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _nearbyArtworks = [];
  bool _isLoading = false;
  String? _error;

  ArtworkProvider(this._artworkService);

  List<Artwork> get nearbyArtworks => _nearbyArtworks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNearbyArtworks(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _nearbyArtworks = await _artworkService.getNearbyArtworks(
        latitude,
        longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsDiscovered(int artworkId) async {
    final success = await _artworkService.markArtworkAsDiscovered(artworkId);
    if (success) {
      notifyListeners();
    }
    return success;
  }
} 