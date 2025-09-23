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
      totalBlogs: json['totalBlogs'] ?? 0,
      publishedBlogs: json['publishedBlogs'] ?? 0,
      draftBlogs: json['draftBlogs'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      bookmarksCount: json['bookmarksCount'] ?? 0,
      recentActivity: json['recentActivity'] ?? 0,
      joinedDate: json['joinedDate'] != null 
          ? DateTime.parse(json['joinedDate'])
          : DateTime.now(),
    );
  }
}