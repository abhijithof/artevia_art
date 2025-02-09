import 'package:flutter/material.dart';
import '../services/artwork_service.dart';
import '../models/artwork_model.dart';

class NearbyArtworks extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  const NearbyArtworks({
    Key? key, 
    required this.latitude, 
    required this.longitude
  }) : super(key: key);

  @override
  State<NearbyArtworks> createState() => _NearbyArtworksState();
}

class _NearbyArtworksState extends State<NearbyArtworks> {
  final ArtworkService _artworkService = ArtworkService();
  List<Artwork> _artworks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    try {
      final artworks = await _artworkService.getNearbyArtworks(
        widget.latitude,
        widget.longitude,
      );
      
      setState(() {
        _artworks = artworks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artworks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_artworks.isEmpty) {
      return const Center(
        child: Text(
          'No artworks found nearby',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _artworks.length,
      itemBuilder: (context, index) {
        final artwork = _artworks[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: artwork.imageUrl != null
                ? Image.network(artwork.imageUrl!)
                : const Icon(Icons.image),
            title: Text(artwork.title),
            subtitle: Text(artwork.description),
            trailing: artwork.isFeatured
                ? const Icon(Icons.star, color: Colors.amber)
                : null,
          ),
        );
      },
    );
  }
} 