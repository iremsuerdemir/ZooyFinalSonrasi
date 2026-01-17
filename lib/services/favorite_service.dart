import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favori_item.dart';
import '../config/api_config.dart';

class FavoriteService {
  static String get baseUrl => ApiConfig.userFavoritesUrl;

  final http.Client httpClient;

  FavoriteService({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID from SharedPreferences (login data)
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get all favorites for current user, optionally filtered by tip (e.g. "caregiver")
  Future<List<FavoriteItem>> getUserFavorites({String? tip}) async {
    try {
      final userId = await _getCurrentUserId();
      // Eğer kullanıcı login değilse favorileri boş dön
      if (userId == null) {
        return [];
      }

      // URL'yi güvenli şekilde oluştur
      final queryParams = <String, String>{
        'userId': userId.toString(),
      };
      if (tip != null && tip.isNotEmpty) {
        queryParams['tip'] = tip;
      }

      // Base URL içinde zaten query varsa, Uri.parse doğru çalışmayabilir, 
      // ancak burada baseUrl'in temiz bir URL olduğunu varsayıyoruz.
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      final response = await httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Modeldeki fromJson metodunu kullan
        return data.map((json) => FavoriteItem.fromJson(json)).toList();
      }
      
      print("Favoriler yüklenirken hata: ${response.statusCode}");
      return [];
    } catch (e) {
      print('Favori yükleme hatası: $e');
      return [];
    }
  }

  /// Add a favorite
  Future<bool> addFavorite(FavoriteItem favorite) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final response = await httpClient
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'title': favorite.title,
              'subtitle': favorite.subtitle,
              'imageUrl': favorite.imageUrl,
              'profileImageUrl': favorite.profileImageUrl,
              'tip': favorite.tip,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Favori ekleme hatası: $e');
      return false;
    }
  }

  /// Remove a favorite by identifier
  Future<bool> removeFavorite({
    required String title,
    required String tip,
    String? imageUrl,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      var url = '$baseUrl/by-identifier?userId=$userId&title=${Uri.encodeComponent(title)}&tip=${Uri.encodeComponent(tip)}';
      if (imageUrl != null && imageUrl.isNotEmpty) {
        url += '&imageUrl=${Uri.encodeComponent(imageUrl)}';
      }

      final response = await httpClient
          .delete(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Favori silme hatası: $e');
      return false;
    }
  }

  /// Check if an item is favorite
  Future<bool> isFavorite({
    required String title,
    required String tip,
    String? imageUrl,
  }) async {
    try {
      final favorites = await getUserFavorites(tip: tip);
      return favorites.any((f) {
        if (f.title == title && f.tip == tip) {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return f.imageUrl == imageUrl;
          }
          return true;
        }
        return false;
      });
    } catch (e) {
      print('Favori kontrol hatası: $e');
      return false;
    }
  }

  /// Get favorite count for a specific item
  Future<int> getFavoriteCount({
    required String title,
    required String tip,
    String? imageUrl,
  }) async {
    try {
      var url = '$baseUrl/count?title=${Uri.encodeComponent(title)}&tip=${Uri.encodeComponent(tip)}';
      if (imageUrl != null && imageUrl.isNotEmpty) {
        url += '&imageUrl=${Uri.encodeComponent(imageUrl)}';
      }

      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return int.parse(response.body);
      }
      return 0;
    } catch (e) {
      print('Favori sayısı alma hatası: $e');
      return 0;
    }
  }

  /// Get all users who favorited a specific item
  Future<List<Map<String, dynamic>>> getFavoriteUsers({
    required String title,
    required String tip,
    String? imageUrl,
  }) async {
    try {
      var url = '$baseUrl/users?title=${Uri.encodeComponent(title)}&tip=${Uri.encodeComponent(tip)}';
      if (imageUrl != null && imageUrl.isNotEmpty) {
        url += '&imageUrl=${Uri.encodeComponent(imageUrl)}';
      }

      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => {
          'userId': json['userId'],
          'displayName': json['displayName'] ?? 'Bilinmeyen Kullanıcı',
          'photoUrl': json['photoUrl'],
        }).toList();
      }
      return [];
    } catch (e) {
      print('Favori kullanıcıları alma hatası: $e');
      return [];
    }
  }
}

