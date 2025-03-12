import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/artwork_provider.dart';
import '../models/artwork_model.dart';
import '../models/comment_model.dart';
import '../../../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  int _likeCount = 0;
  bool _showingCommentsView = false;
  bool _showAllComments = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkIfLiked();
    _getLikeCount();
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

  Future<void> _getLikeCount() async {
    try {
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      final count = await artworkProvider.artworkService.getLikeCount(widget.artwork.id);
      setState(() => _likeCount = count);
    } catch (e) {
      print('Error getting like count: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final artworkProvider = Provider.of<ArtworkProvider>(context, listen: false);
      final success = _isLiked 
          ? await artworkProvider.artworkService.unlikeArtwork(widget.artwork.id)
          : await artworkProvider.artworkService.likeArtwork(widget.artwork.id);
      
      if (success) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
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

  Widget _buildLatestComment() {
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No comments yet'),
      );
    }

    final latestComment = _comments.last;
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Comment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showingCommentsView = true;
                  });
                },
                child: Text('View All (${_comments.length})'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(latestComment.username[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latestComment.username,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(latestComment.text),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.separated(
      controller: _scrollController,
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
                    child: Text(comment.username[0].toUpperCase()),
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
    );
  }

  Widget _buildCommentsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showingCommentsView = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(comment.username[0].toUpperCase()),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.username,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(comment.text),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isUserArtwork = widget.artwork.artistId == authProvider.user?.id;
    final bool canViewContent = widget.artwork.isUnlocked || isUserArtwork;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _showingCommentsView 
        ? _buildCommentsView()
        : Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Image
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      ApiService.getImageUrl(widget.artwork.imageUrl ?? ''),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image_not_supported, 
                               size: 40, 
                               color: Colors.grey),
                        );
                      },
                    ),
                    // Only show lock overlay if not user's artwork and not unlocked
                    if (!canViewContent)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          backgroundBlendMode: BlendMode.darken,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            if (widget.artwork.canBeUnlocked)
                              ElevatedButton(
                                onPressed: () => widget.onUnlock(widget.artwork.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Unlock Artwork'),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Get closer to unlock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and artist info always visible
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.artwork.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${widget.artwork.artistName}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isUserArtwork)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Your Artwork',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Only show these if unlocked or user's artwork
                      if (canViewContent) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.artwork.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInteractionBar(),
                        if (_comments.isNotEmpty) _buildLatestComment(),
                      ],
                    ],
                  ),
                ),
              ),

              // Comment input only for unlocked or user's artwork
              if (canViewContent)
                _buildCommentInput(),
            ],
          ),
    );
  }

  Widget _buildInteractionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_outline,
              color: _isLiked ? Colors.red : null,
            ),
            onPressed: _toggleLike,
          ),
          Text('$_likeCount'),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showingCommentsView = true;
              });
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text('${_comments.length}'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
} 