import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserServiceApi {
  static String get baseUrl => ApiConfig.userServicesUrl;

  final http.Client httpClient;

  UserServiceApi({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID from SharedPreferences (login data)
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get all services for current user
  Future<List<Map<String, dynamic>>> getUserServices() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final response = await httpClient
          .get(Uri.parse('$baseUrl?userId=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => {
              'id': json['id'],
              'serviceName': json['serviceName'] ?? '',
              'serviceIcon': json['serviceIcon'],
              'price': json['price'],
              'description': json['description'],
              'address': json['address'] ?? '',
            }).toList();
      }
      return [];
    } catch (e) {
      // debugPrint('Servis yükleme hatası: $e');
      return [];
    }
  }

  /// Get services from other users
  Future<List<Map<String, dynamic>>> getOtherUsersServices() async {
    try {
      final userId = await _getCurrentUserId();
      final url = userId != null
          ? '$baseUrl/others?excludeUserId=$userId'
          : '$baseUrl/others?excludeUserId=0';

      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Diğer kullanıcı servisleri yükleme hatası: $e');
      return [];
    }
  }

  /// Create a new service
  Future<bool> createService(Map<String, dynamic> service) async {
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
              'serviceName': service['serviceName'] ?? '',
              'serviceIcon': service['serviceIcon'],
              'price': service['price'],
              'description': service['description'],
              'address': service['address'] ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Servis oluşturma hatası: $e');
      return false;
    }
  }

  /// Delete a service by ID
  Future<bool> deleteService(int serviceId) async {
    try {
      final response = await httpClient
          .delete(Uri.parse('$baseUrl/$serviceId'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Servis silme hatası: $e');
      return false;
    }
  }
}

