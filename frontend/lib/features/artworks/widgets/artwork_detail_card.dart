import 'package:flutter/material.dart';
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info always visible
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('By ${artwork.artistName}'),
                Text('Distance: ${(artwork.distanceFromUser / 1000).toStringAsFixed(2)} km'),
              ],
            ),
          ),

          // Unlock button if within range
          if (artwork.canBeUnlocked && !artwork.isUnlocked)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => onUnlock(artwork.id),
                child: const Text('Unlock Artwork'),
              ),
            ),

          // Full details only if unlocked
          if (artwork.isUnlocked) ...[
            if (artwork.imageUrl != null)
              Image.network(
                artwork.imageUrl!,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(artwork.description),
            ),
            // Social features would go here
          ],
        ],
      ),
    );
  }
} 