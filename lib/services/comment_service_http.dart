import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comment.dart';
import '../config/api_config.dart';

class CommentServiceHttp {
  static String get baseUrl => ApiConfig.userCommentsUrl;

  final http.Client httpClient;

  CommentServiceHttp({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID and name from SharedPreferences (login data)
  Future<Map<String, dynamic>?> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final displayName = prefs.getString('displayName') ?? 'Kullanıcı';
    final photoUrl = prefs.getString('photoUrl');

    if (userId == null) {
      return null;
    }

    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Get comments for a specific card - TÜM KULLANICILARIN yorumlarını getirir
  /// userId filtresi YOK - tüm kullanıcıların yorumları döner
  /// cardId bulunamazsa userName ile filtreleme yapılabilir (geçici çözüm)
  Future<List<Comment>> getCommentsForCard(String cardId,
      {String? userName}) async {
    try {
      var url = '$baseUrl?cardId=${Uri.encodeComponent(cardId)}';
      if (userName != null) {
        url += '&userName=${Uri.encodeComponent(userName)}';
      }
      print('Yorumlar çekiliyor - URL: $url');

      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30)); // Timeout süresini 30 saniyeye çıkar

      print('Backend yanıt kodu: ${response.statusCode}');
      print('Backend yanıt body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            '✅ Yorumlar yüklendi: ${data.length} adet yorum bulundu (cardId: $cardId)');

        if (data.isEmpty) {
          print(
              '⚠️ UYARI: Backend\'den 0 yorum döndü. Bu cardId için yorum yok olabilir: $cardId');
        }

        return data.map((json) {
          print(
              '📝 Yorum bulundu: ${json['authorName']} - ${json['message']} (UserId: ${json['userId']})');
          return Comment.fromJson({
            'id': json['id'].toString(),
            'message': json['message'] ?? '',
            'rating': json['rating'] ?? 5,
            'createdAt': json['createdAt'],
            'authorName': json['authorName'] ?? '',
            'authorAvatar': json['authorAvatar'] as String?,
            'userId': json['userId']?.toString(), // userId ekle
          });
        }).toList();
      }
      print('❌ Yorum yükleme hatası: Status code ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Yorum yükleme hatası: $e');
      return [];
    }
  }

  /// Add a comment
  Future<bool> addComment(String cardId, Comment comment) async {
    try {
      final user = await _getCurrentUser();
      if (user == null) {
        print('❌ Kullanıcı bilgisi bulunamadı! userId null.');
        return false;
      }

      print(
          '✅ Kullanıcı bilgisi: userId=${user['userId']}, displayName=${user['displayName']}');

      // Yorum eklerken profil resmini backend'den User tablosundan çekecek
      // Bu yüzden authorAvatar göndermiyoruz, backend User tablosundan alacak
      final requestBody = {
        'userId': user['userId'],
        'cardId': cardId,
        'message': comment.message,
        'rating': comment.rating,
        'authorName': user['displayName'],
        // authorAvatar göndermiyoruz - backend User tablosundan PhotoUrl'i alacak
      };

      print('📤 Yorum gönderiliyor: $requestBody');
      print('📤 URL: $baseUrl');

      final response = await httpClient
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30)); // Timeout süresini 30 saniyeye çıkar

      print('📥 Yorum ekleme yanıtı:');
      print('   Status: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        print('❌ Yorum ekleme başarısız! Status: ${response.statusCode}');
        print('❌ Hata mesajı: ${response.body}');
        return false;
      }

      print('✅ Yorum başarıyla eklendi!');
      return true;
    } catch (e, stackTrace) {
      print('❌ Yorum ekleme hatası: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete a specific comment by ID - sadece kendi yorumunu silebilir
  Future<bool> deleteComment(int commentId) async {
    try {
      final user = await _getCurrentUser();
      if (user == null) {
        print('❌ Kullanıcı bilgisi bulunamadı! userId null.');
        return false;
      }

      final url = '$baseUrl/$commentId?userId=${user['userId']}';
      print('🗑️ Yorum siliniyor - URL: $url');

      final response = await httpClient
          .delete(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      print('📥 Yorum silme yanıtı: Status=${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Yorum başarıyla silindi!');
        return true;
      } else {
        print('❌ Yorum silme başarısız! Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Yorum silme hatası: $e');
      return false;
    }
  }

  /// Delete comments for a card
  Future<bool> deleteCommentsForCard(String cardId) async {
    try {
      final response = await httpClient
          .delete(Uri.parse(
              '$baseUrl/by-card?cardId=${Uri.encodeComponent(cardId)}'))
          .timeout(const Duration(seconds: 30)); // Timeout süresini 30 saniyeye çıkar

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Yorum silme hatası: $e');
      return false;
    }
  }

  /// Get comment count for a card
  Future<int> getCommentCountForCard(String cardId) async {
    try {
      final comments = await getCommentsForCard(cardId);
      return comments.length;
    } catch (e) {
      print('Yorum sayısı alma hatası: $e');
      return 0;
    }
  }

  /// DEBUG: Tüm yorumları getir (cardId kontrolü için)
  Future<void> debugGetAllComments() async {
    try {
      final url = '$baseUrl/all';
      print('🔍 DEBUG: Tüm yorumlar çekiliyor - URL: $url');

      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30)); // Timeout süresini 30 saniyeye çıkar

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('🔍 DEBUG: Backend\'de toplam ${data.length} yorum var:');
        for (var comment in data) {
          print(
              '  - Id: ${comment['id']}, CardId: ${comment['cardId']}, UserId: ${comment['userId']}, Author: ${comment['authorName']}');
        }
      } else {
        print('❌ DEBUG: Yorumlar alınamadı, Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG hatası: $e');
    }
  }
}
