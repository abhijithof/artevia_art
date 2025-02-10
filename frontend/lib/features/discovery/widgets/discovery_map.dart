import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../artworks/providers/artwork_provider.dart';
import '../../artworks/models/artwork_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DiscoveryMap extends StatefulWidget {
  const DiscoveryMap({Key? key}) : super(key: key);

  @override
  State<DiscoveryMap> createState() => _DiscoveryMapState();
}

class _DiscoveryMapState extends State<DiscoveryMap> {
  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() => _currentPosition = position);

      print('Current position: ${position.latitude}, ${position.longitude}');

      // Fetch artworks using the provider
      final provider = Provider.of<ArtworkProvider>(context, listen: false);
      await provider.fetchNearbyArtworks(position.latitude, position.longitude);

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtworkProvider>(
      builder: (context, artworkProvider, child) {
        print('Building map with ${artworkProvider.artworks.length} artworks');
        
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(10.0889, 76.2784),
                zoom: 15.0,
                onMapReady: () {
                  print('Map is ready');
                  if (artworkProvider.artworks.isNotEmpty) {
                    final bounds = LatLngBounds.fromPoints(
                      artworkProvider.artworks.map((a) => 
                        LatLng(a.latitude, a.longitude)
                      ).toList()
                    );
                    _mapController.fitBounds(
                      bounds,
                      options: const FitBoundsOptions(padding: EdgeInsets.all(50))
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: kIsWeb 
                    ? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: kIsWeb ? ['a', 'b', 'c'] : const [],
                  userAgentPackageName: 'com.artevia.app',
                ),
                MarkerLayer(
                  markers: [
                    // Current location marker
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
                    // Artwork markers with lock icon
                    ...artworkProvider.artworks.map((artwork) {
                      print('Creating marker for: ${artwork.title} at (${artwork.latitude}, ${artwork.longitude})');
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
                              color: artwork.isDiscovered ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              artwork.isDiscovered ? Icons.lock_open : Icons.lock,
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
            // Debug overlay
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Artworks loaded: ${artworkProvider.artworks.length}'),
                    if (_currentPosition != null) ...[
                      Text('Your location:'),
                      Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}'),
                      Text('Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'),
                    ],
                    if (artworkProvider.artworks.isNotEmpty) ...[
                      const Text('First artwork:'),
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void _showArtworkDetails(Artwork artwork) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine your location')),
      );
      return;
    }

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      artwork.latitude,
      artwork.longitude,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 34,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 12),
              Text(
                'Distance: ${(distance / 1000).toStringAsFixed(2)} km',
                style: TextStyle(
                  color: distance <= 1000 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              if (distance <= 1000) ...[
                if (!artwork.isDiscovered) ...[
                  const Text(
                    'You are close enough to unlock this artwork!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (artwork.imageUrl != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          size: 48,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _unlockArtwork(artwork),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Unlock Artwork',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  if (artwork.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        artwork.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    artwork.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Get within 1 km of the artwork to unlock it! You are ${(distance / 1000).toStringAsFixed(2)} km away.',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (artwork.imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        size: 48,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlockArtwork(Artwork artwork) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine your location')),
      );
      return;
    }

    try {
      final provider = Provider.of<ArtworkProvider>(context, listen: false);
      await provider.unlockArtwork(
        artwork.id,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${artwork.title} unlocked!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 