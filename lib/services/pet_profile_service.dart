import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';

class PetProfileService {
  static String get baseUrl => ApiConfig.petProfilesUrl;

  final http.Client httpClient;

  PetProfileService({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// Get current user ID from SharedPreferences (login data)
  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get all pets for the current user
  /// GET: /api/petprofiles/my?userId={userId}
  Future<List<PetProfileModel>> getMyPets() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final response = await httpClient
          .get(Uri.parse('$baseUrl/my?userId=$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PetProfileModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Pet profilleri yükleme hatası: $e');
      return [];
    }
  }

  /// Create a new pet profile
  /// POST: /api/petprofiles?userId={userId}
  Future<Map<String, dynamic>> createPet({
    required String userId,
    required String name,
    required String species,
    String? breed,
    int? age, // <-- TÜM SORUNU ÇÖZEN ANA DÜZELTME
    String? weight,
    String? vaccinationStatus,
    String? healthNotes,
    required String ownerName,
    required String ownerContact,
  }) async {
    try {
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'Kullanıcı ID bulunamadı. Lütfen giriş yapın.',
        };
      }

      final requestBody = {
        'name': name,
        'species': species,
        if (breed != null) 'breed': breed,
        if (age != null) 'age': age, // <-- AGE ARTIK INT
        if (weight != null) 'weight': weight,
        if (vaccinationStatus != null)
          'vaccinationStatus': vaccinationStatus,
        if (healthNotes != null) 'healthNotes': healthNotes,
        'ownerName': ownerName,
        'ownerContact': ownerContact,
      };

      final response = await httpClient
          .post(
            Uri.parse('$baseUrl?userId=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Pet profili başarıyla oluşturuldu.',
          'data': jsonDecode(response.body),
        };
      } else {
        String errorMessage = 'Pet profili kaydedilirken bir hata oluştu.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Pet profili oluşturma hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  /// Update a pet profile
  /// PUT: /api/petprofiles/{id}?userId={userId}
  Future<Map<String, dynamic>> updatePet({
    required String id,
    required String name,
    required String species,
    String? breed,
    int? age,
    String? weight,
    String? vaccinationStatus,
    String? healthNotes,
    required String ownerName,
    required String ownerContact,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'Kullanıcı ID bulunamadı. Lütfen giriş yapın.',
        };
      }

      final requestBody = {
        'name': name,
        'species': species,
        if (breed != null) 'breed': breed,
        if (age != null) 'age': age,
        if (weight != null) 'weight': weight,
        if (vaccinationStatus != null) 'vaccinationStatus': vaccinationStatus,
        if (healthNotes != null) 'healthNotes': healthNotes,
        'ownerName': ownerName,
        'ownerContact': ownerContact,
      };

      final response = await httpClient
          .put(
            Uri.parse('$baseUrl/$id?userId=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Pet profili başarıyla güncellendi.',
        };
      } else {
        String errorMessage = 'Pet profili güncellenirken bir hata oluştu.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Pet profili güncelleme hatası: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }

  /// Delete a pet profile
  Future<bool> deletePet(String id) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final response = await httpClient
          .delete(Uri.parse('$baseUrl/$id?userId=$userId'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Pet profili silme hatası: $e');
      return false;
    }
  }
}
