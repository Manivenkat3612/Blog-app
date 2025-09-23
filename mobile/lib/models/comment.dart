import 'user.dart';

class Comment {
  final String id;
  final String content;
  final User author;
  final String blogId;
  final String? parentId;
  final List<Comment> replies;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.blogId,
    this.parentId,
    this.replies = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Create a default author if none provided
    Map<String, dynamic> authorJson = json['author'] ?? {
      '_id': 'unknown',
      'name': 'Anonymous',
      'email': 'anonymous@example.com',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    return Comment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      author: User.fromJson(authorJson),
      blogId: json['blog']?.toString() ?? json['blogId']?.toString() ?? '',
      parentId: json['parentComment']?.toString() ?? json['parentId']?.toString(),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => Comment.fromJson(reply))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'author': author.toJson(),
      'blogId': blogId,
      'parentId': parentId,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? content,
    User? author,
    String? blogId,
    String? parentId,
    List<Comment>? replies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      blogId: blogId ?? this.blogId,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}