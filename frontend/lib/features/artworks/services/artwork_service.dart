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

  Future<List<Artwork>> getUnlockedArtworks() async {
    try {
      final response = await _dio.get(
        '/artworks/unlocked',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> artworksJson = response.data;
        return artworksJson.map((json) => Artwork.fromJson(json)).toList();
      }
      throw Exception('Failed to load unlocked artworks');
    } catch (e) {
      print('Error getting unlocked artworks: $e');
      rethrow;
    }
  }

  Future<bool> unlockArtwork(int artworkId) async {
    try {
      print('Attempting to unlock artwork: $artworkId');
      final response = await _dio.post(
        '/artworks/unlock',
        data: {
          'artwork_id': artworkId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      
      print('Unlock response: ${response.data}');
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

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get(
        '/artworks/categories',
        options: Options(
          headers: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> categoriesJson = response.data;
        return categoriesJson.map((c) => c.toString()).toList();
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  Future<void> createArtwork(FormData formData, String artistName) async {
    try {
      print('Sending artwork data: ${formData.fields}');
      
      // Add artist name to form data
      formData.fields.add(MapEntry('artist_name', artistName));
      
      final response = await _dio.post(
        '/artworks',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode != 201) {
        throw Exception('Failed to create artwork: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating artwork: $e');
      rethrow;
    }
  }

  Future<void> deleteArtwork(int id) async {
    try {
      final response = await _dio.delete(
        '/artworks/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete artwork: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteArtwork service: $e');
      rethrow;
    }
  }
} 