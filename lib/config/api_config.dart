import 'package:flutter/foundation.dart';

/// API Configuration
///
/// Production için backend URL'ini buradan değiştirebilirsiniz
class ApiConfig {
  // Development URL (Local network)
  // static const String devBaseUrl = 'http://192.168.34.149:5001';
  
  static String get devBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
       // Android Emulator için 10.0.2.2 kullanılır. Fiziksel cihaz için buraya IP yazın.
       // return 'http://10.0.2.2:5001';
       return 'http://192.168.34.149:5001';
    } else {
       return 'http://localhost:5001';
    }
  }

  // Production URL - Buraya production URL'inizi yazın
  static const String prodBaseUrl = 'https://your-production-api.com';

  // Environment (development veya production)
  static const bool isProduction = false; // Production'da true yapın

  /// Base URL getter
  static String get baseUrl {
    return isProduction ? prodBaseUrl : devBaseUrl;
  }

  /// API Base URL (with /api prefix)
  static String get apiBaseUrl {
    return '$baseUrl/api';
  }

  // Specific endpoints
  static String get authUrl => '$apiBaseUrl/auth';
  static String get userRequestsUrl => '$apiBaseUrl/userrequests';
  static String get userFavoritesUrl => '$apiBaseUrl/userfavorites';
  static String get userCommentsUrl => '$apiBaseUrl/usercomments';
  static String get userServicesUrl => '$apiBaseUrl/userservices';
  static String get usersUrl => '$apiBaseUrl/users';
  static String get messagesUrl => '$apiBaseUrl/messages';
  static String get notificationsUrl => '$apiBaseUrl/notifications';
  static String get petProfilesUrl => '$apiBaseUrl/petprofiles';
}
