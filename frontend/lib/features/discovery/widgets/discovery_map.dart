import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../artworks/providers/artwork_provider.dart';
import '../../artworks/models/artwork_model.dart';

class DiscoveryMap extends StatefulWidget {
  const DiscoveryMap({Key? key}) : super(key: key);

  @override
  State<DiscoveryMap> createState() => _DiscoveryMapState();
}

class _DiscoveryMapState extends State<DiscoveryMap> {
  final MapController _mapController = MapController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        
        final provider = Provider.of<ArtworkProvider>(context, listen: false);
        await provider.fetchNearbyArtworks(
          position.latitude,
          position.longitude,
        );

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _showArtworkDetails(Artwork artwork) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artwork.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (artwork.imageUrl != null)
              Image.network(
                artwork.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 8),
            Text(artwork.description),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtworkProvider>(
      builder: (context, artworkProvider, child) {
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(10.0889, 76.2784),
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.artevia.app',
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ...artworkProvider.artworks.map((artwork) {
                      return Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(artwork.latitude, artwork.longitude),
                        child: GestureDetector(
                          onTap: () => _showArtworkDetails(artwork),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.palette,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Artworks loaded: ${artworkProvider.artworks.length}'),
                    if (_currentPosition != null) ...[
                      Text('Your location:'),
                      Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}'),
                      Text('Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'),
                    ],
                    if (artworkProvider.artworks.isNotEmpty) ...[
                      Text('First artwork:'),
                      Text(artworkProvider.artworks.first.title),
                      Text('(${artworkProvider.artworks.first.latitude}, ${artworkProvider.artworks.first.longitude})'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 