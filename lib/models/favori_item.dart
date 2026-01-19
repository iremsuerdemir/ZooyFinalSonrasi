import 'dart:convert';

class FavoriteItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String profileImageUrl;
  final String tip; // "explore", "moments", "caregiver" gibi
  final int? targetUserId; // Takip edilen kullanıcının ID'si (opsiyonel)

  FavoriteItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.profileImageUrl,
    required this.tip,
    this.targetUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "subtitle": subtitle,
      "imageUrl": imageUrl,
      "profileImageUrl": profileImageUrl,
      "tip": tip,
      "targetUserId": targetUserId,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      title: json["title"] ?? "Başlıksız",
      subtitle: json["subtitle"] ?? "",
      imageUrl: json["imageUrl"] ?? "",
      profileImageUrl: json["profileImageUrl"] ?? "",
      tip: json["tip"] ?? "caregiver",
      targetUserId: json["targetUserId"],
    );
  }

  static String encode(List<FavoriteItem> items) =>
      json.encode(items.map((e) => e.toJson()).toList());

  static List<FavoriteItem> decode(String items) =>
      (json.decode(items) as List<dynamic>)
          .map<FavoriteItem>((e) => FavoriteItem.fromJson(e))
          .toList();
}
