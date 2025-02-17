class Comment {
  final int id;
  final int artworkId;
  final int userId;
  final String username;
  final String content;
  final String createdAt;

  Comment({
    required this.id,
    required this.artworkId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      artworkId: json['artwork_id'],
      userId: json['user_id'],
      username: json['username'],
      content: json['content'],
      createdAt: json['created_at'],
    );
  }
} 