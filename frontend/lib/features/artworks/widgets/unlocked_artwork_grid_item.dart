import 'package:flutter/material.dart';
import '../models/artwork_model.dart';
import '../../../services/api_service.dart';
import '../widgets/artwork_detail_card.dart';

class UnlockedArtworkGridItem extends StatelessWidget {
  final Artwork artwork;

  const UnlockedArtworkGridItem({
    Key? key,
    required this.artwork,
  }) : super(key: key);

  void _showArtworkDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ArtworkDetailCard(
        artwork: artwork,
        onUnlock: (_) {}, // Empty callback since it's already unlocked
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showArtworkDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              child: artwork.imageUrl != null && artwork.imageUrl!.isNotEmpty
                  ? Image.network(
                      ApiService.getImageUrl(artwork.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              Text('Image not available', 
                                   style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          Text('No image available', 
                               style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artwork.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'By ${artwork.artistName}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 