import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/artwork_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/artwork_model.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  void _showDeleteConfirmation(BuildContext context, Artwork artwork, ArtworkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: Text('Are you sure you want to delete "${artwork.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteArtwork(artwork.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Artwork deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete artwork: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ArtworkProvider, AuthProvider>(
      builder: (context, artworkProvider, authProvider, _) {
        if (artworkProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userArtworks = artworkProvider.artworks
            .where((artwork) => artwork.artistId == authProvider.user?.id)
            .toList();

        if (userArtworks.isEmpty) {
          return const Center(
            child: Text('You haven\'t uploaded any artworks yet'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => artworkProvider.refreshArtworks(),
          child: ListView.builder(
            itemCount: userArtworks.length,
            itemBuilder: (context, index) {
              final artwork = userArtworks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (artwork.imageUrl != null)
                      Image.network(
                        artwork.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artwork.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(artwork.description),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Location: (${artwork.latitude.toStringAsFixed(4)}, ${artwork.longitude.toStringAsFixed(4)})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(
                                  context,
                                  artwork,
                                  artworkProvider,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
} 