class Artwork {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final int artistId;
  final String status;
  final bool isFeatured;
  final DateTime? createdAt;

  Artwork({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.artistId,
    required this.status,
    required this.isFeatured,
    this.createdAt,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      artistId: json['artist_id'],
      status: json['status'],
      isFeatured: json['is_featured'],
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'])
        : null,
    );
  }
} 