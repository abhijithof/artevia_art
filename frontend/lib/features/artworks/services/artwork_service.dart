import 'package:dio/dio.dart';
import '../models/artwork_model.dart';

class ArtworkService {
  final Dio _dio;
  final String? authToken;

  ArtworkService(this._dio, {this.authToken});

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude, {double radius = 5.0}) async {
    try {
      final response = await _dio.get(
        '/artworks/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
        options: Options(
          headers: authToken != null ? {
            'Authorization': 'Bearer $authToken',
          } : null,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> artworksJson = response.data;
        return artworksJson.map((json) => Artwork.fromJson(json)).toList();
      }
      throw Exception('Failed to load artworks: ${response.statusCode}');
    } catch (e) {
      print('Error in getNearbyArtworks: $e');
      rethrow;
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

  Future<void> unlockArtwork(int artworkId, double latitude, double longitude) async {
    try {
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.post(
        '/discoveries/artworks/$artworkId/unlock',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['detail'] ?? 'Failed to unlock artwork');
      }
    } catch (e) {
      print('Error unlocking artwork: $e');
      rethrow;
    }
  }
} 