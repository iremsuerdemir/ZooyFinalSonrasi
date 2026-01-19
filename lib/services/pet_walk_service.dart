import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/pet_walk_model.dart';

class PetWalkService {

  Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<List<PetWalk>> getWalks() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return [];

      // Eğer local/emulator problemi varsa localhost yerine IP kullanıldığından emin olun.
      // ApiConfig.apiBaseUrl şöyledir: http://(IP):5001/api
      final url = '${ApiConfig.apiBaseUrl}/PetWalks/user/$userId';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PetWalk.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load walks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading walks: $e');
      return [];
    }
  }

  Future<bool> saveWalk(PetWalk walk) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;
      
      // userId'yi override edelim ki güvenilir olsun
      final walkData = walk.toJson();
      walkData['userId'] = userId;

      final url = '${ApiConfig.apiBaseUrl}/PetWalks';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(walkData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to save walk. Status: ${response.statusCode} Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error saving walk: $e');
      return false;
    }
  }
}
