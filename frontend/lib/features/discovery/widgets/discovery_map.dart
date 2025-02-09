import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../artworks/providers/artwork_provider.dart';

class DiscoveryMap extends StatefulWidget {
  const DiscoveryMap({Key? key}) : super(key: key);

  @override
  State<DiscoveryMap> createState() => _DiscoveryMapState();
}

class _DiscoveryMapState extends State<DiscoveryMap> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
      });

      print('Current position: ${position.latitude}, ${position.longitude}');

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0
      );

      // Use the provider to load artworks
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      await artworkProvider.fetchNearbyArtworks(position.latitude, position.longitude);
      
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ...artworkProvider.artworks.map((artwork) {
                      print('Adding marker for: ${artwork.title}');
                      return Marker(
                        point: LatLng(artwork.latitude, artwork.longitude),
                        child: GestureDetector(
                          onTap: () => _showArtworkDetails(artwork),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            // Location refresh button
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _isLoading 
                  ? null 
                  : _getCurrentLocation,
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.my_location),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showArtworkDetails(artwork) {
    // Implement artwork details modal
  }
} 