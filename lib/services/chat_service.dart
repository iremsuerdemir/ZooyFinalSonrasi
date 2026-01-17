import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../config/api_config.dart';

class ChatService {
  static String get baseUrl => ApiConfig.messagesUrl;

  final http.Client httpClient;

  ChatService({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID from SharedPreferences
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get messages for a specific job between current user and another user
  /// Login olan kullanıcı sadece kendisine ait mesajları görmeli
  Future<List<Message>> getMessages(int jobId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final response = await httpClient
          .get(Uri.parse('$baseUrl?jobId=$jobId&userId=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Mesaj yükleme hatası: $e');
      return [];
    }
  }

  /// Send a message
  Future<Message?> sendMessage({
    required int receiverId,
    required int jobId,
    required String messageText,
  }) async {
    try {
      final senderId = await _getCurrentUserId();
      if (senderId == null) {
        return null;
      }

      final response = await httpClient
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'senderId': senderId,
              'receiverId': receiverId,
              'jobId': jobId,
              'messageText': messageText,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      return null;
    }
  }
}

