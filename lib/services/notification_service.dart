import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../config/api_config.dart';

class NotificationService {
  static String get baseUrl => ApiConfig.notificationsUrl;

  final http.Client httpClient;

  NotificationService({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID from SharedPreferences
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get all notifications for current user
  /// Login olan kullanıcı sadece kendisine ait bildirimleri görmeli
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId <= 0) {
        print('⚠️ Geçersiz userId: $userId - Bildirimler yüklenemiyor');
        return [];
      }

      print('📥 Bildirimler yükleniyor - userId: $userId');
      final response = await httpClient
          .get(Uri.parse('$baseUrl?userId=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
        print('✅ ${notifications.length} bildirim yüklendi - userId: $userId');
        return notifications;
      } else {
        print('❌ Bildirim yükleme hatası - Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Bildirim yükleme hatası: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await httpClient
          .put(Uri.parse('$baseUrl/$notificationId/read'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Bildirim okundu işaretleme hatası: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await httpClient
          .delete(Uri.parse('$baseUrl/$notificationId'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Bildirim silme hatası: $e');
      return false;
    }
  }
}

