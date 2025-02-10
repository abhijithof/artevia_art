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
} 