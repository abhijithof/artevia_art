import 'package:dio/dio.dart';
import '../models/artwork_model.dart';

class ArtworkService {
  final Dio _dio;

  ArtworkService(this._dio);

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/artworks/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': 5.0,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List)
            .map((json) => Artwork.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting nearby artworks: $e');
      return [];
    }
  }

  Future<bool> markArtworkAsDiscovered(int artworkId) async {
    try {
      final response = await _dio.post('/discoveries/$artworkId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking artwork as discovered: $e');
      return false;
    }
  }
} 