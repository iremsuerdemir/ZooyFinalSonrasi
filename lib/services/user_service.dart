import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zoozy/models/user_model.dart';
import '../config/api_config.dart';

class UserService {
  static String get baseUrl => ApiConfig.usersUrl;

  // -------------------------------------------------------------
  // 🔥 Kullanıcı var mı?
  // -------------------------------------------------------------
  Future<bool> userExists(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/exists/$firebaseUid");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["exists"] == true;
    }
    return false;
  }

  // -------------------------------------------------------------
  // 🆕 İlk kayıt (register)
  // -------------------------------------------------------------
  Future<String?> registerUser(AppUser user) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 409) return "USER_EXISTS";
    if (response.statusCode == 201 || response.statusCode == 200) {
      return "SUCCESS";
    }

    return null;
  }

  // -------------------------------------------------------------
  // 🔄 Login sonrası senkronizasyon (her girişte)
  // -------------------------------------------------------------
  Future<bool> syncUser(AppUser user) async {
    final url = Uri.parse("$baseUrl/sync");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );

    return response.statusCode == 200;
  }

  // -------------------------------------------------------------
  // 🔥 Backend'den kullanıcı bilgisi çek
  // -------------------------------------------------------------
  Future<AppUser?> getUser(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/$firebaseUid");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  // -------------------------------------------------------------
  // 🔄 Kullanıcı profil güncelleme (PhotoUrl dahil)
  // PUT: api/users/{id}
  // -------------------------------------------------------------
  Future<bool> updateUserProfile({
    required int userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/$userId");

      final body = <String, dynamic>{};
      if (displayName != null && displayName.trim().isNotEmpty) {
        body['displayName'] = displayName.trim();
      }
      // Sadece geçerli base64 string gönder
      if (photoUrl != null &&
          photoUrl.trim().isNotEmpty &&
          photoUrl.trim().startsWith('data:image')) {
        body['photoUrl'] = photoUrl.trim();
        print('📤 PhotoUrl gönderiliyor (uzunluk: ${photoUrl.length})');
      } else if (photoUrl != null) {
        print(
            '⚠️ Geçersiz PhotoUrl formatı, gönderilmiyor: ${photoUrl.substring(0, photoUrl.length > 50 ? 50 : photoUrl.length)}');
      }

      if (body.isEmpty) {
        print('⚠️ Güncellenecek alan yok');
        return false;
      }

      print('📤 Backend\'e gönderiliyor: $body');

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print(
          '📥 Backend yanıtı: Status ${response.statusCode}, Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Profil güncelleme hatası: $e');
      return false;
    }
  }
}
