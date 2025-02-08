import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../artworks/providers/artwork_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../artworks/models/artwork_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      _loadNearbyArtworks();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadNearbyArtworks() async {
    if (_currentPosition != null) {
      await context.read<ArtworkProvider>().loadNearbyArtworks(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Artworks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyArtworks,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.artevia.app',
          ),
          MarkerLayer(
            markers: [
              // Current location marker
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              // Artwork markers from provider
              ...context.watch<ArtworkProvider>().nearbyArtworks.map(
                    (artwork) => Marker(
                      point: LatLng(artwork.latitude, artwork.longitude),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showArtworkDetails(artwork),
                        child: const Icon(
                          Icons.art_track,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation
        },
      ),
    );
  }

  void _showArtworkDetails(Artwork artwork) {
    // TODO: Show artwork details modal
  }
}