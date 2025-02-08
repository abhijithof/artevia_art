class Artwork {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String artistId;

  Artwork({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.artistId,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      artistId: json['artist_id'],
    );
  }
} 