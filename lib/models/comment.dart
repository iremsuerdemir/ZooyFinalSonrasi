class Comment {
  final String id;
  final String message;
  final int rating; // 1-5 arası yıldız
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatar;
  final String? userId; // Yorum sahibinin userId'si

  Comment({
    required this.id,
    required this.message,
    required this.rating,
    required this.createdAt,
    required this.authorName,
    this.authorAvatar,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'authorName': authorName,
      'authorAvatar': authorAvatar ?? '',
      'userId': userId ?? '',
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      message: json['message'],
      rating: json['rating'],
      createdAt: DateTime.parse(json['createdAt']),
      authorName: json['authorName'],
      authorAvatar: json['authorAvatar'] as String?,
      userId: json['userId'] as String?,
    );
  }
}
