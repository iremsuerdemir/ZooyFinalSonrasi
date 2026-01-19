# IP Yapılandırma Rehberi

## ✅ Mevcut Durumunuz

`ipconfig` sonucuna göre:
- **Wi-Fi IPv4 Address:** `192.168.34.149`
- Bu IP zaten `lib/config/api_config.dart` dosyasında ayarlı ✅

## 📱 Hangi IP'yi Kullanmalısınız?

### Senaryo 1: Fiziksel Telefon/Tablet ile Test
**Kullanın:** `192.168.34.149` (Wi-Fi IP'niz)

**Gereksinimler:**
- ✅ Backend'iniz bu IP'de çalışıyor olmalı
- ✅ Telefon/tablet aynı WiFi ağında olmalı
- ✅ Windows Firewall port 5001'i engellememeli

### Senaryo 2: Android Emulator ile Test
**Kullanın:** `10.0.2.2` (Android emulator için özel IP)

**Not:** Android emulator, host bilgisayarın localhost'una `10.0.2.2` ile erişir.

### Senaryo 3: iOS Simulator ile Test
**Kullanın:** `localhost` veya `127.0.0.1`

**Not:** iOS simulator host bilgisayarın localhost'una direkt erişir.

### Senaryo 4: Web (Chrome/Edge) ile Test
**Kullanın:** `localhost` veya `127.0.0.1`

## 🔧 IP'yi Nasıl Değiştirirsiniz?

`lib/config/api_config.dart` dosyasında:

```dart
// Fiziksel cihaz için (mevcut ayar)
static const String devBaseUrl = 'http://192.168.34.149:5001';

// Android Emulator için
static const String devBaseUrl = 'http://10.0.2.2:5001';

// iOS Simulator veya Web için
static const String devBaseUrl = 'http://localhost:5001';
```

## 🔥 Windows Firewall Ayarları

Backend'e erişim için port 5001'i açmanız gerekebilir:

### Yöntem 1: PowerShell (Yönetici olarak)
```powershell
New-NetFirewallRule -DisplayName "Zoozy API" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
```

### Yöntem 2: Windows Defender Firewall GUI
1. Windows Defender Firewall'u açın
2. "Gelen Kuralları" → "Yeni Kural"
3. "Bağlantı Noktası" → İleri
4. TCP, 5001 → İleri
5. "Bağlantıya İzin Ver" → İleri
6. Tüm profilleri seçin → İleri
7. İsim: "Zoozy API" → Son

## ✅ Test Etme

### 1. Backend'in Çalıştığını Kontrol Edin
Tarayıcıda açın:
- `http://192.168.34.149:5001/swagger` (fiziksel cihaz için)
- `http://localhost:5001/swagger` (emulator/simulator için)

### 2. Flutter Uygulamasından Test
1. Flutter uygulamasını başlatın
2. Login yapın
3. Requests Screen'e gidin
4. Network request'lerin gittiğini kontrol edin

### 3. Network Bağlantısını Kontrol Edin
- Flutter DevTools → Network sekmesi
- HTTP request'lerin başarılı olduğunu kontrol edin
- Hata varsa IP ve port'u kontrol edin

## 🚨 Yaygın Sorunlar

### "Connection refused" hatası
**Sebep:** Backend çalışmıyor veya yanlış IP
**Çözüm:**
- Backend'in çalıştığından emin olun
- IP adresini kontrol edin
- Firewall ayarlarını kontrol edin

### "Network is unreachable" hatası
**Sebep:** Cihazlar farklı ağlarda
**Çözüm:**
- Telefon/tablet ve bilgisayar aynı WiFi'de olmalı
- IP adresini tekrar kontrol edin

### Emulator'de çalışmıyor
**Sebep:** Yanlış IP kullanılıyor
**Çözüm:**
- Android Emulator: `10.0.2.2` kullanın
- iOS Simulator: `localhost` kullanın

## 📝 IP Adresiniz Değişirse

WiFi değiştirdiğinizde veya IP adresiniz değiştiğinde:

1. `ipconfig` komutunu çalıştırın
2. Yeni IPv4 adresini bulun (Wi-Fi adapter altında)
3. `lib/config/api_config.dart` dosyasındaki `devBaseUrl`'i güncelleyin
4. Flutter uygulamasını yeniden başlatın

## 🎯 Önerilen Ayarlar

### Development için:
```dart
static const String devBaseUrl = 'http://192.168.34.149:5001'; // Fiziksel cihaz
// veya
static const String devBaseUrl = 'http://10.0.2.2:5001'; // Android Emulator
```

### Production için:
```dart
static const String prodBaseUrl = 'https://api.zoozy.com'; // Production domain
static const bool isProduction = true;
```

