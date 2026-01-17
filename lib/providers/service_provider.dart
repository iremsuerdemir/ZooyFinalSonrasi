import 'package:flutter/material.dart';
import 'package:zoozy/services/user_service_api.dart';

class ServiceProvider extends ChangeNotifier {
  /// Yeni sistem – tüm servis kartları burada tutulur
  List<Map<String, dynamic>> services = [];

  /// Geçici servis bilgileri (AddService → Describe → Rate → Location)
  Map<String, dynamic> tempServiceDetails = {};

  /// Eski sistemden gelen alanlar (HATA almaman için geri eklendi)
  String selectedServiceName = "";
  String fullAddress = "";

  /// Backend API service
  final UserServiceApi _userServiceApi = UserServiceApi();
  bool _isLoading = false;

  /// -----------------------------
  ///  GEÇİCİ SERVİS BİLGİLERİ
  /// -----------------------------
  void setTempServiceDetails(Map<String, dynamic> details) {
    tempServiceDetails.addAll(details);
    notifyListeners();
  }

  /// Load services from backend
  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final backendServices = await _userServiceApi.getUserServices();
      services = backendServices;
    } catch (e) {
      print('Servis yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;

  /// AddLocation'dan gelen final adım
  Future<bool> finalizeService(String address) async {
    fullAddress = address;
    tempServiceDetails["address"] = address;

    final serviceData = {
      "serviceName": tempServiceDetails["serviceName"] ?? selectedServiceName,
      "serviceIcon": tempServiceDetails["serviceIcon"],
      "price": tempServiceDetails["price"],
      "description": tempServiceDetails["description"],
      "address": address,
    };

    // Save to backend
    final success = await _userServiceApi.createService(serviceData);

    if (success) {
      // Reload services from backend to get the ID
      await loadServices();
    } else {
      // Still add to local list even if backend save fails (for offline support)
      services.add(serviceData);
    }

    tempServiceDetails = {};
    notifyListeners();
    return success;
  }

  /// -----------------------------
  ///   ESKİ METOTLAR – KULLANDIĞIN EKRANLAR İÇİN EKLENDİ
  /// -----------------------------

  void setService(String name) {
    selectedServiceName = name;

    /// Yeni sisteme de otomatik ekleyelim
    tempServiceDetails["serviceName"] = name;

    notifyListeners();
  }

  void setAddress(String address) {
    fullAddress = address;

    /// Yeni sisteme de ekleyelim
    tempServiceDetails["address"] = address;

    notifyListeners();
  }

  /// Eski addService çağrıları bozulmasın diye bıraktım
  void addService(String name, String address) {
    services.add({
      "serviceName": name,
      "address": address,
    });
    notifyListeners();
  }

  /// Servis sil
  Future<bool> removeService(int index) async {
    if (index >= 0 && index < services.length) {
      final service = services[index];
      final serviceId = service['id'] as int?;
      debugPrint('[SİLME DEBUG] Silinmek istenen service id: $serviceId');
      debugPrint('[SİLME DEBUG] Service içeriği: ${service.toString()}');
      if (serviceId != null) {
        final success = await _userServiceApi.deleteService(serviceId);
        debugPrint(
            '[SİLME DEBUG] Backend deleteService cevabı: $success (id=$serviceId)');
        if (success) {
          services.removeAt(index);
          notifyListeners();
          return true;
        } else {
          debugPrint(
              '[SİLME DEBUG] Backend deleteService false döndü (id=$serviceId)');
          return false;
        }
      } else {
        debugPrint('[SİLME DEBUG] serviceId null, localden siliyor...');
        services.removeAt(index);
        notifyListeners();
        return true;
      }
    }
    debugPrint('[SİLME DEBUG] Silinmek istenen index geçersiz: $index');
    return false;
  }

  /// Hepsini temizle
  void clearAll() {
    services.clear();
    selectedServiceName = "";
    fullAddress = "";
    tempServiceDetails = {};
    notifyListeners();
  }
}
