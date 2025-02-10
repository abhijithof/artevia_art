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
  bool isDiscovered;
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
    this.isDiscovered = false,
    this.createdAt,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      artistId: json['artist_id'] is String ? int.parse(json['artist_id']) : json['artist_id'] as int,
      status: json['status'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      isDiscovered: false, // Default to not discovered
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
} 