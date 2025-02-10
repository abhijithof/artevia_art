import 'package:flutter/foundation.dart';
import '../services/artwork_service.dart';
import '../models/artwork_model.dart';

class ArtworkProvider extends ChangeNotifier {
  final ArtworkService _artworkService;
  List<Artwork> _artworks = [];
  bool _isLoading = false;
  String? _error;

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
} 