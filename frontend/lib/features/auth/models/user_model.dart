class User {
  final int id;
  final String email;
  final String username;
  final bool isActive;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.isActive,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isArtist => role == 'artist';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      isActive: json['is_active'] ?? false,
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
} 