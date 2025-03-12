class Comment {
  final int id;
  final int artworkId;
  final int userId;
  final String username;
  final String text;
  final String createdAt;

  Comment({
    required this.id,
    required this.artworkId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      artworkId: json['artwork_id'],
      userId: json['user_id'],
      username: json['username'],
      text: json['text'],
      createdAt: json['created_at'],
    );
  }
} 