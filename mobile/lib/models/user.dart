class User {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> bookmarks;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.bookmarks = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      avatar: json['avatar'] ?? json['profilePicture'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      bookmarks: List<String>.from(json['bookmarks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bookmarks': bookmarks,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? bookmarks,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}