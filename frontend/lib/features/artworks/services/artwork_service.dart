import 'package:dio/dio.dart';
import 'package:frontend/services/api_service.dart';
import '../models/artwork_model.dart';
import '../models/comment_model.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';


class ArtworkService {
  final Dio _dio;
  final String? authToken;

  ArtworkService(this._dio, {this.authToken}) {
    _dio.options.baseUrl = ApiService.baseUrl;  // Use the dynamic base URL
    if (authToken != null) {
      _dio.options.headers = {
        'Authorization': 'Bearer $authToken',
      };
    }
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
    _dio.options.sendTimeout = const Duration(seconds: 3);
  }

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/artworks/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          // Ensure the image URL is properly formatted
          if (json['image_url'] != null) {
            json['image_url'] = ApiService.getImageUrl(json['image_url']);
          }
          return Artwork.fromJson(json);
        }).toList();
      }
      throw Exception('Failed to load nearby artworks');
    } catch (e) {
      print('Error getting nearby artworks: $e');
      rethrow;
    }
  }

  Future<List<Artwork>> getUnlockedArtworks() async {
    try {
      // First get the unlocked artworks
      final unlockedResponse = await _dio.get(
        '/artworks/user/unlocked',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      if (unlockedResponse.statusCode == 200) {
        final List<dynamic> artworksJson = unlockedResponse.data;
        
        // Get artist details for each artwork
        List<Artwork> artworks = [];
        for (var json in artworksJson) {
          // Get artist details
          final artistId = json['artist_id'];
          String artistName = 'Unknown Artist';
          
          try {
            final artistResponse = await _dio.get(
              '/users/$artistId',
              options: Options(
                headers: {'Authorization': 'Bearer $authToken'},
              ),
            );
            
            if (artistResponse.statusCode == 200) {
              artistName = artistResponse.data['username'] ?? 'Unknown Artist';
            }
          } catch (e) {
            print('Error getting artist details: $e');
          }

          // Ensure the image URL is properly formatted
          if (json['image_url'] != null) {
            json['image_url'] = ApiService.getImageUrl(json['image_url']);
          }
          
          artworks.add(Artwork.fromJson(
            json,
            isUnlocked: true,
            artistName: artistName,
          ));
        }
        
        return artworks;
      }
      
      print('Error response: ${unlockedResponse.data}');
      throw Exception('Failed to load unlocked artworks: ${unlockedResponse.statusCode}');
    } catch (e) {
      print('Error getting unlocked artworks: $e');
      rethrow;
    }
  }

  Future<bool> unlockArtwork(int artworkId) async {
    try {
      final response = await _dio.post(
        '/artworks/unlock',
        data: {'artwork_id': artworkId},
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        // After successful unlock, refresh the unlocked artworks list
        await getUnlockedArtworks();
        return true;
      }
      return false;
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

  Future<void> createArtwork(FormData formData) async {
    try {
      final response = await _dio.post(
        '/artworks/',
        data: formData,
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
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

  // Add like to artwork
  Future<bool> likeArtwork(int artworkId) async {
    try {
      final response = await _dio.post(
        '/artworks/$artworkId/like',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking artwork: $e');
      rethrow;
    }
  }

  // Remove like from artwork
  Future<bool> unlikeArtwork(int artworkId) async {
    try {
      final response = await _dio.delete(
        '/artworks/$artworkId/like',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error unliking artwork: $e');
      rethrow;
    }
  }

  // Get comments for artwork
  Future<List<Comment>> getComments(int artworkId) async {
    try {
      final response = await _dio.get('/artworks/$artworkId/comments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Add comment to artwork
  Future<Comment?> addComment(int artworkId, String text) async {
    try {
      final response = await _dio.post(
        '/artworks/$artworkId/comments',
        data: {'text': text},
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Provide a default username if none is provided
        data['username'] = data['username'] ?? 'Unknown User';
        return Comment.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Future<int> getLikeCount(int artworkId) async {
    try {
      final response = await _dio.get('/artworks/$artworkId/likes/count');
      if (response.statusCode == 200) {
        return response.data['count'];
      }
      return 0;
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }
} 