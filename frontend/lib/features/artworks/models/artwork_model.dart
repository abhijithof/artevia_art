class Artwork {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;  // Nullable since it's hidden until unlocked
  final double latitude;
  final double longitude;
  final String artistName;
  final bool isUnlocked;
  final double distanceFromUser;  // Add this to track distance

  Artwork({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.artistName,
    this.isUnlocked = false,
    this.distanceFromUser = double.infinity,
  });

  bool get canBeUnlocked => distanceFromUser <= 1000; // 1km in meters

  factory Artwork.fromJson(Map<String, dynamic> json, {double distanceFromUser = double.infinity}) {
    return Artwork(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      latitude: (json['latitude'] is String) 
          ? double.parse(json['latitude']) 
          : json['latitude']?.toDouble() ?? 0.0,
      longitude: (json['longitude'] is String) 
          ? double.parse(json['longitude']) 
          : json['longitude']?.toDouble() ?? 0.0,
      artistName: json['artist_name'] ?? 'Unknown Artist',
      isUnlocked: json['is_unlocked'] ?? false,
      distanceFromUser: distanceFromUser,
    );
  }
} 