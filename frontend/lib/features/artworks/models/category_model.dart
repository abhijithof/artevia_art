class ArtworkCategory {
  final String name;
  
  ArtworkCategory({
    required this.name,
  });

  factory ArtworkCategory.fromJson(dynamic json) {
    return ArtworkCategory(
      name: json is String ? json : json['name'],
    );
  }

  @override
  String toString() => name;
} 