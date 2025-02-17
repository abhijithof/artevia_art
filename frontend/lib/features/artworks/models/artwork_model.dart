class Artwork {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String artistName;
  final int artistId;
  final bool isUnlocked;
  final double distanceFromUser;

  Artwork({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.artistName,
    required this.artistId,
    this.isUnlocked = false,
    this.distanceFromUser = double.infinity,
  });

  bool get canBeUnlocked => distanceFromUser <= 1000;

  Artwork copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? artistName,
    int? artistId,
    bool? isUnlocked,
    double? distanceFromUser,
  }) {
    return Artwork(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }

  factory Artwork.fromJson(Map<String, dynamic> json, {double distanceFromUser = double.infinity}) {
    // Convert distance from meters to kilometers if it's provided in the JSON
    final distance = json['distance'] != null 
        ? (json['distance'] is String 
            ? double.parse(json['distance']) 
            : json['distance'].toDouble())
        : distanceFromUser / 1000; // Convert Geolocator distance from meters to km

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
      artistId: json['artist_id'] is String 
          ? int.parse(json['artist_id']) 
          : json['artist_id'],
      isUnlocked: json['is_unlocked'] ?? false,
      distanceFromUser: distance,
    );
  }
}