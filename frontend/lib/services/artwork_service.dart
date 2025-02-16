import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artwork_model.dart';

class ArtworkService {
  // For Android Emulator, use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://10.0.2.2:8000';  // Changed from localhost

  Future<List<Artwork>> getNearbyArtworks(double latitude, double longitude) async {
    try {
      print('1. Starting API request...');
      final url = '$baseUrl/artworks/nearby?latitude=$latitude&longitude=$longitude';
      print('2. Request URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('3. Response status code: ${response.statusCode}');
      print('4. Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        print('5. Parsing JSON response...');
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('6. JSON list length: ${jsonList.length}');
        
        for (var i = 0; i < jsonList.length; i++) {
          print('7. Processing artwork $i:');
          print('   Raw JSON: ${jsonList[i]}');
          try {
            final artwork = Artwork.fromJson(jsonList[i]);
            print('   Parsed successfully: ${artwork.title}');
          } catch (e) {
            print('   Error parsing artwork $i: $e');
          }
        }

        final artworks = jsonList.map((json) => Artwork.fromJson(json)).toList();
        print('8. Successfully parsed ${artworks.length} artworks');
        return artworks;
      } else {
        print('Error: Bad response status code');
        throw Exception('Failed to load artworks: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in getNearbyArtworks:');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      return [];
    }
  }
} 