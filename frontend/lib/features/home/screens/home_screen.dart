import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

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
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    final artworks = context.read<ArtworkProvider>().nearbyArtworks;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        ...artworks.map(
          (artwork) => Marker(
            markerId: MarkerId('artwork_${artwork.id}'),
            position: LatLng(artwork.latitude, artwork.longitude),
            infoWindow: InfoWindow(
              title: artwork.title,
              snippet: artwork.description,
              onTap: () => _showArtworkDetails(artwork),
            ),
          ),
        ),
      };
    });
  }

  void _showArtworkDetails(Artwork artwork) {
    // TODO: Show artwork details modal
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final artworkProvider = context.watch<ArtworkProvider>();
    final user = authProvider.user;
    final isArtist = user?.role == 'artist';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Artworks (${artworkProvider.nearbyArtworks.length} found)',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyArtworks,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentPosition == null)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          if (artworkProvider.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (artworkProvider.error != null)
            Center(
              child: Text(artworkProvider.error!),
            ),
        ],
      ),
      floatingActionButton: isArtist
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement artwork upload
              },
              child: const Icon(Icons.add_photo_alternate),
            )
          : null,
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
} 