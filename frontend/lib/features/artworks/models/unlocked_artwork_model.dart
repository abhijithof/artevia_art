class UnlockedArtwork {
  final int id;
  final int artworkId;
  final int userId;
  final String unlockedAt;

  UnlockedArtwork({
    required this.id,
    required this.artworkId,
    required this.userId,
    required this.unlockedAt,
  });

  factory UnlockedArtwork.fromJson(Map<String, dynamic> json) {
    return UnlockedArtwork(
      id: json['id'],
      artworkId: json['artwork_id'],
      userId: json['user_id'],
      unlockedAt: json['unlocked_at'],
    );
  }
} 