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
  final ScrollController _scrollController = ScrollController();
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
      
      if (comment != null) {
        setState(() {
          _comments.add(comment);
          _commentController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar at the top
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Artwork details section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.artwork.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${widget.artwork.artistName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.artwork.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Comments section
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        comment.username[0].toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      comment.username,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Comment input section
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _addComment,
                      color: Theme.of(context).primaryColor,
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