import 'package:dio/dio.dart';
import '../models/artwork_model.dart';

class ArtworkService {
  final Dio _dio;

  ArtworkService(this._dio);

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude, {double radius = 5.0}) async {
    try {
      print('Fetching artworks at: $latitude, $longitude');
      
      final response = await _dio.get(
        '/artworks/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> artworksJson = response.data;
        return artworksJson.map((json) => Artwork.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load artworks: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error getting nearby artworks: $e');
      print('Stack trace: $stackTrace');
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