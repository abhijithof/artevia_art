import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../artworks/providers/artwork_provider.dart';
import '../../artworks/models/artwork_model.dart';
import '../../artworks/widgets/artwork_detail_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../artworks/widgets/add_artwork_form.dart';

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
        await provider.updateCurrentPosition(position);

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Widget _buildArtworkMarker(Artwork artwork, AuthProvider authProvider) {
    final bool isUserArtwork = artwork.artistId == authProvider.user?.id;
    
    return GestureDetector(
      onTap: () => _showArtworkDetails(artwork),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUserArtwork 
            ? Colors.blue.withOpacity(0.8)
            : artwork.isUnlocked 
              ? Colors.green.withOpacity(0.8) 
              : Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Icon(
          isUserArtwork 
            ? Icons.palette
            : artwork.isUnlocked 
              ? Icons.lock_open 
              : Icons.lock,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showArtworkDetails(Artwork artwork) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ArtworkDetailCard(
        artwork: artwork,
        onUnlock: (id) async {
          try {
            final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
            await artworkProvider.unlockArtwork(id);
            Navigator.pop(context); // Close the bottom sheet
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to unlock artwork: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ArtworkProvider, AuthProvider>(
      builder: (context, artworkProvider, authProvider, _) {
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
                        child: _buildArtworkMarker(artwork, authProvider),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 200,
              child: FloatingActionButton(
                heroTag: "refreshLocation",
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.refresh_rounded),
                mini: true,
              ),
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
            if (authProvider.isArtist)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showAddArtworkDialog(),
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddArtworkDialog() {
    if (_currentPosition == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddArtworkForm(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
    );
  }
} 