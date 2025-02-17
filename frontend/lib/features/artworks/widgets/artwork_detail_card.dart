import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/artwork_model.dart';


class ArtworkDetailCard extends StatelessWidget {
  final Artwork artwork;
  final Function(int) onUnlock;

  const ArtworkDetailCard({
    Key? key,
    required this.artwork,
    required this.onUnlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isUserArtwork = artwork.artistId == authProvider.user?.id;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(artwork.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artwork.description),
                const SizedBox(height: 8),
                Text('Artist: ${artwork.artistName}'),
                Text('Distance: ${artwork.distanceFromUser.toStringAsFixed(2)} km'),
              ],
            ),
          ),
          if (!isUserArtwork && !artwork.isUnlocked)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => onUnlock(artwork.id),
                child: const Text('Unlock Artwork'),
              ),
            ),
        ],
      ),
    );
  }
} 