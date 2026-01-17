class NotificationModel {
  final int id;
  final int userId;
  final String type; // "job" veya "message"
  final String title;
  final int? relatedUserId;
  final int? relatedJobId;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedUsername;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.relatedUserId,
    this.relatedJobId,
    required this.createdAt,
    required this.isRead,
    this.relatedUsername,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      relatedUserId: json['relatedUserId'] as int?,
      relatedJobId: json['relatedJobId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedUsername: json['relatedUsername'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      if (relatedUserId != null) 'relatedUserId': relatedUserId,
      if (relatedJobId != null) 'relatedJobId': relatedJobId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (relatedUsername != null) 'relatedUsername': relatedUsername,
    };
  }
}

