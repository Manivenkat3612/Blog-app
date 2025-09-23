class UserStats {
  final int totalBlogs;
  final int publishedBlogs;
  final int draftBlogs;
  final int totalLikes;
  final int totalComments;
  final int bookmarksCount;
  final int recentActivity;
  final DateTime joinedDate;

  UserStats({
    required this.totalBlogs,
    required this.publishedBlogs,
    required this.draftBlogs,
    required this.totalLikes,
    required this.totalComments,
    required this.bookmarksCount,
    required this.recentActivity,
    required this.joinedDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalBlogs: (json['totalBlogs'] as num?)?.toInt() ?? 0,
      publishedBlogs: (json['publishedBlogs'] as num?)?.toInt() ?? 0,
      draftBlogs: (json['draftBlogs'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarksCount'] as num?)?.toInt() ?? 0,
      recentActivity: (json['recentActivity'] as num?)?.toInt() ?? 0,
      joinedDate: json['joinedDate'] != null 
          ? DateTime.tryParse(json['joinedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}