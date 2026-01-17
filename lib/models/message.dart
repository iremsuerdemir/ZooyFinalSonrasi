class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final int jobId;
  final String messageText;
  final DateTime createdAt;
  final String? senderUsername;
  final String? receiverUsername;
  final String? senderPhotoUrl;
  final String? receiverPhotoUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.jobId,
    required this.messageText,
    required this.createdAt,
    this.senderUsername,
    this.receiverUsername,
    this.senderPhotoUrl,
    this.receiverPhotoUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      jobId: json['jobId'] as int,
      messageText: json['messageText'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderUsername: json['senderUsername'] as String?,
      receiverUsername: json['receiverUsername'] as String?,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      receiverPhotoUrl: json['receiverPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'jobId': jobId,
      'messageText': messageText,
      'createdAt': createdAt.toIso8601String(),
      if (senderUsername != null) 'senderUsername': senderUsername,
      if (receiverUsername != null) 'receiverUsername': receiverUsername,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      if (receiverPhotoUrl != null) 'receiverPhotoUrl': receiverPhotoUrl,
    };
  }
}
