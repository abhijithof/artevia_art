import 'package:flutter/material.dart';
import '../models/artwork_model.dart';
import '../../../services/api_service.dart';

class ArtworkGridItem extends StatelessWidget {
  final Artwork artwork;
  final VoidCallback onDelete;

  const ArtworkGridItem({
    Key? key,
    required this.artwork,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image container with same error handling as ArtworkDetailCard
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
          // Title overlay at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Text(
                artwork.title,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Delete button overlay at the top right
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
} 