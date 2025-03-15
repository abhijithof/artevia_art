class ArtworkCategory {
  final String id;
  final String name;
  
  ArtworkCategory({
    required this.id,
    required this.name,
  });

  factory ArtworkCategory.fromString(String categoryName) {
    return ArtworkCategory(
      id: categoryName,  // Using the name as the ID for string-based categories
      name: categoryName,
    );
  }

  factory ArtworkCategory.fromJson(Map<String, dynamic> json) {
    return ArtworkCategory(
      id: json['id'].toString(),
      name: json['name'],
    );
  }

  @override
  String toString() => name;
} 