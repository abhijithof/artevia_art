class Artwork {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String artistId;
  final String status;
  final bool isFeatured;
  final bool isDiscovered;
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
    String idString = json['id'].toString();
    String artistIdString = json['artist_id'].toString();

    return Artwork(
      id: idString,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      artistId: artistIdString,
      status: json['status'] as String,
      isFeatured: json['is_featured'] as bool,
      isDiscovered: json['is_discovered'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  // Add toString() for debugging
  @override
  String toString() {
    return 'Artwork{id: $id, title: $title, lat: $latitude, lng: $longitude}';
  }

  // Add a debug print method
  void debugPrint() {
    print('Artwork{');
    print('  id: $id (${id.runtimeType})');
    print('  title: $title (${title.runtimeType})');
    print('  latitude: $latitude (${latitude.runtimeType})');
    print('  longitude: $longitude (${longitude.runtimeType})');
    print('  artistId: $artistId (${artistId.runtimeType})');
    print('}');
  }
} 