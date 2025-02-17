import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/artwork_provider.dart';
import '../widgets/unlocked_artwork_grid_item.dart';

class UnlockedArtworksScreen extends StatelessWidget {
  const UnlockedArtworksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlocked Artworks'),
      ),
      body: Consumer<ArtworkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unlockedArtworks = provider.unlockedArtworks;

          if (unlockedArtworks.isEmpty) {
            return const Center(
              child: Text('No unlocked artworks yet'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: unlockedArtworks.length,
            itemBuilder: (context, index) {
              final artwork = unlockedArtworks[index];
              return UnlockedArtworkGridItem(artwork: artwork);
            },
          );
        },
      ),
    );
  }
} 