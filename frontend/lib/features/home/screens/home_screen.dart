import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../discovery/widgets/discovery_map.dart';
import '../../artworks/providers/artwork_provider.dart';
import '../../artworks/screens/collection_screen.dart';
import '../../artworks/screens/unlocked_artworks_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeUnlockedArtworks();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      await context.read<ArtworkProvider>().fetchNearbyArtworks(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _initializeUnlockedArtworks() async {
    try {
      await context.read<ArtworkProvider>().fetchUnlockedArtworks();
    } catch (e) {
      print('Error initializing unlocked artworks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DiscoveryMap(),
          CollectionScreen(),
          UnlockedArtworksScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            _initializeUnlockedArtworks();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette_outlined),
            activeIcon: Icon(Icons.palette),
            label: 'My Art',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_open_outlined),
            activeIcon: Icon(Icons.lock_open),
            label: 'Unlocked',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}