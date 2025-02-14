import 'package:dio/dio.dart';
import '../models/artwork_model.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class ArtworkService {
  final Dio _dio;
  final String? authToken;

  ArtworkService(this._dio, {this.authToken});

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/artworks/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': 5.0,
        },
        options: Options(
          headers: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> artworksJson = response.data;
        return artworksJson.map((json) {
          try {
            final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              json['latitude'] is String ? double.parse(json['latitude']) : json['latitude'],
              json['longitude'] is String ? double.parse(json['longitude']) : json['longitude'],
            );
            return Artwork.fromJson(json, distanceFromUser: distance);
          } catch (e) {
            print('Error parsing artwork: $e');
            print('Raw JSON: $json');
            rethrow;
          }
        }).toList();
      }
      throw Exception('Failed to load artworks: ${response.statusCode}');
    } catch (e) {
      print('Error in getNearbyArtworks: $e');
      rethrow;
    }
  }

  // Add unlock artwork endpoint
  Future<bool> unlockArtwork(int artworkId) async {
    try {
      final response = await _dio.post(
        '/artworks/$artworkId/unlock',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error unlocking artwork: $e');
      rethrow;
    }
  }

  // Get full artwork details (only for unlocked artworks)
  Future<Artwork> getArtworkDetails(int artworkId) async {
    try {
      final response = await _dio.get(
        '/artworks/$artworkId',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      return Artwork.fromJson(response.data);
    } catch (e) {
      print('Error getting artwork details: $e');
      rethrow;
    }
  }

  Future<void> createArtwork({
    required String title,
    required String description,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'image': await MultipartFile.fromFile(imageFile.path),
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await _dio.post(
        '/artworks/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create artwork');
      }
    } catch (e) {
      print('Error creating artwork: $e');
      rethrow;
    }
  }
} 