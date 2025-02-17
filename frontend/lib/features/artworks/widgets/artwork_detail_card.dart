import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/artwork_provider.dart';
import '../models/artwork_model.dart';
import '../models/comment_model.dart';
import '../../../services/api_service.dart';

class ArtworkDetailCard extends StatefulWidget {
  final Artwork artwork;
  final Function(int) onUnlock;

  const ArtworkDetailCard({
    Key? key,
    required this.artwork,
    required this.onUnlock,
  }) : super(key: key);

  @override
  State<ArtworkDetailCard> createState() => _ArtworkDetailCardState();
}

class _ArtworkDetailCardState extends State<ArtworkDetailCard> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkIfLiked();
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoading = true);
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      final comments = await artworkProvider.artworkService.getComments(widget.artwork.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfLiked() async {
    // Implement check if user has liked artwork
  }

  Future<void> _toggleLike() async {
    try {
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      final success = _isLiked 
          ? await artworkProvider.artworkService.unlikeArtwork(widget.artwork.id)
          : await artworkProvider.artworkService.likeArtwork(widget.artwork.id);
      
      if (success) {
        setState(() => _isLiked = !_isLiked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      final comment = await artworkProvider.artworkService.addComment(
        widget.artwork.id,
        _commentController.text,
      );
      
      setState(() {
        _comments.add(comment);
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isUserArtwork = widget.artwork.artistId == authProvider.user?.id;
    
    // Get the artist name from auth provider if it's the user's artwork
    final displayArtistName = isUserArtwork 
        ? authProvider.user?.username 
        : widget.artwork.artistName;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                child: widget.artwork.imageUrl != null && widget.artwork.imageUrl!.isNotEmpty
                    ? Image.network(
                        ApiService.getImageUrl(widget.artwork.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                Text('Image not available', style: TextStyle(color: Colors.grey)),
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
                            Text('No image available', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              ListTile(
                title: Text(widget.artwork.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.artwork.description),
                    const SizedBox(height: 8),
                    Text('Artist: ${displayArtistName ?? "Unknown Artist"}'),
                    if (!widget.artwork.isUnlocked)
                      Text('Distance: ${widget.artwork.distanceFromUser.toStringAsFixed(2)} km'),
                  ],
                ),
              ),
              if (!isUserArtwork && !widget.artwork.isUnlocked)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => widget.onUnlock(widget.artwork.id),
                    child: const Text('Unlock Artwork'),
                  ),
                ),
              IconButton(
                icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                color: _isLiked ? Colors.red : null,
                onPressed: _toggleLike,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            title: Text(comment.username),
                            subtitle: Text(comment.content),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  left: 8,
                  right: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 