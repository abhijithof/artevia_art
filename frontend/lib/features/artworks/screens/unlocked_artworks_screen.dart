import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/artwork_provider.dart';

class UnlockedArtworksScreen extends StatelessWidget {
  const UnlockedArtworksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtworkProvider>(
      builder: (context, artworkProvider, _) {
        if (artworkProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final unlockedArtworks = artworkProvider.unlockedArtworks;

        if (unlockedArtworks.isEmpty) {
          return const Center(
            child: Text('You haven\'t unlocked any artworks yet'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: unlockedArtworks.length,
          itemBuilder: (context, index) {
            final artwork = unlockedArtworks[index];
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: artwork.imageUrl != null
                        ? Image.network(
                            artwork.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artwork.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'By ${artwork.artistName}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 