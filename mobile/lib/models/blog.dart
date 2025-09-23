import 'user.dart';

class Blog {
  final String id;
  final String title;
  final String content;
  final String? excerpt;
  final String? featuredImage;
  final List<String> tags;
  final String category;
  final User author;
  final List<String> likes;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBookmarked;
  final bool isLiked;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    this.featuredImage,
    required this.tags,
    required this.category,
    required this.author,
    required this.likes,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.isBookmarked = false,
    this.isLiked = false,
  });

  static List<String> _extractUserIds(List<dynamic> items) {
    return items.map((item) {
      if (item is String) {
        return item;
      } else if (item is Map<String, dynamic> && item['user'] != null) {
        return item['user'].toString();
      }
      return '';
    }).where((id) => id.isNotEmpty).toList();
  }

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'],
      featuredImage: json['featuredImage'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? '',
      author: User.fromJson(json['author'] ?? {}),
      likes: _extractUserIds(json['likes'] ?? []),
      likesCount: json['likeCount'] ?? json['likesCount'] ?? 0,
      commentsCount: json['commentCount'] ?? json['commentsCount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isBookmarked: json['isBookmarked'] ?? false,
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'featuredImage': featuredImage,
      'tags': tags,
      'category': category,
      'author': author.toJson(),
      'likes': likes,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
    };
  }

  Blog copyWith({
    String? id,
    String? title,
    String? content,
    String? excerpt,
    String? featuredImage,
    List<String>? tags,
    String? category,
    User? author,
    List<String>? likes,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBookmarked,
    bool? isLiked,
  }) {
    return Blog(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      featuredImage: featuredImage ?? this.featuredImage,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}