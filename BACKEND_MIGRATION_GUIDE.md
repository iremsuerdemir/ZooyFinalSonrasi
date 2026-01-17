# Backend Migration Guide - SharedPreferences to SQL Server

Bu doküman, Flutter uygulamasındaki SharedPreferences ve manuel listelerin C# WebAPI ve SQL Server'a nasıl taşındığını açıklar.

## 📋 Özet

Tüm kullanıcı verileri (Requests, Favorites, Comments, Services) artık SQL Server'da saklanıyor. SharedPreferences sadece login bilgileri için kullanılıyor.

## 🗄️ Veritabanı Tabloları

### 1. UserRequests
Kullanıcıların oluşturduğu hizmet talepleri (Requests Screen).

### 2. UserFavorites
Kullanıcı favorileri (Explore, Moments, Caregiver).

### 3. UserComments
Kullanıcı yorumları (Moments, Caregiver Profiles).

### 4. UserServices
Profil ekranındaki hizmet kartları.

## 🔧 Kurulum Adımları

### 1. SQL Server Migration Script
`ZoozyApi/Migrations/CreateUserDataTables.sql` dosyasını çalıştırın:
- SSMS'te database'inize bağlanın
- SQL script'i çalıştırın
- Veritabanı adını değiştirmeyi unutmayın (`USE [YourDatabaseName];`)

### 2. Entity Framework Migration (Opsiyonel)
Alternatif olarak, EF Core migration kullanabilirsiniz:

```bash
cd ZoozyApi
dotnet ef migrations add AddUserDataTables
dotnet ef database update
```

### 3. Backend API URL'i
Flutter servislerinde backend URL'ini güncelleyin:
- `lib/services/request_service.dart`
- `lib/services/favorite_service.dart`
- `lib/services/comment_service_http.dart`
- `lib/services/user_service_api.dart`

Varsayılan URL: `http://192.168.34.149:5001/api/`

**ÖNEMLİ:** Production'da HTTPS kullanın ve CORS ayarlarını kısıtlayın!

## 📁 Yeni Dosyalar

### Backend (C#)
- `ZoozyApi/Models/UserRequest.cs`
- `ZoozyApi/Models/UserFavorite.cs`
- `ZoozyApi/Models/UserComment.cs`
- `ZoozyApi/Models/UserService.cs`
- `ZoozyApi/Controllers/UserRequestsController.cs`
- `ZoozyApi/Controllers/UserFavoritesController.cs`
- `ZoozyApi/Controllers/UserCommentsController.cs`
- `ZoozyApi/Controllers/UserServicesController.cs`

### Flutter
- `lib/services/request_service.dart`
- `lib/services/favorite_service.dart`
- `lib/services/comment_service_http.dart`
- `lib/services/user_service_api.dart`

## 🔄 Değişiklik Yapılan Dosyalar

### Flutter Screens
- `lib/screens/reguests_screen.dart` - SharedPreferences → HTTP
- `lib/screens/pet_pickup_page.dart` - Backend'e kaydetme
- `lib/screens/favori_page.dart` - SharedPreferences → HTTP
- `lib/screens/profile_screen.dart` - Services backend entegrasyonu
- `lib/components/moments_postCard.dart` - Favorites ve Comments → HTTP
- `lib/screens/caregiverProfilPage.dart` - Favorites ve Comments → HTTP

### Providers
- `lib/providers/service_provider.dart` - Backend entegrasyonu

### Models
- `lib/models/request_item.dart` - ID field eklendi

## 🔐 Login/Auth Değişiklikleri

**ÖNEMLİ:** Login sistemi hiçbir şekilde değiştirilmedi!
- `lib/services/auth_service.dart` - Değişiklik YOK
- SharedPreferences login için hala kullanılıyor (userId, email, displayName, etc.)
- Backend servisleri login verilerini SharedPreferences'tan okuyor

## 🚀 Test Senaryoları

1. **Requests**
   - Yeni talep oluştur → Backend'e kaydedilmeli
   - Talepleri listele → Backend'den çekilmeli
   - Talep sil → Backend'den silinmeli

2. **Favorites**
   - Favori ekle → Backend'e kaydedilmeli
   - Favorileri listele → Backend'den çekilmeli
   - Favori sil → Backend'den silinmeli

3. **Comments**
   - Yorum ekle → Backend'e kaydedilmeli
   - Yorumları listele → Backend'den çekilmeli

4. **Services**
   - Hizmet ekle (Profile Screen) → Backend'e kaydedilmeli
   - Hizmetleri listele → Backend'den çekilmeli
   - Hizmet sil → Backend'den silinmeli

## ⚠️ Notlar

1. **Offline Support:** Flutter tarafında hata durumunda kullanıcıya bildirim gösteriliyor, ancak offline desteği yok. İleride eklenebilir.

2. **Error Handling:** Tüm servisler try-catch ile korumalı ve hata durumlarında kullanıcıya bilgi veriliyor.

3. **Loading States:** UI'da loading göstergeleri eklendi.

4. **Data Migration:** Mevcut SharedPreferences verileri otomatik olarak migrate edilmiyor. Kullanıcıların verileri yeniden eklemesi gerekecek.

## 🔍 API Endpoints

### UserRequests
- `GET /api/userrequests?userId={id}` - Kullanıcının taleplerini getir
- `POST /api/userrequests` - Yeni talep oluştur
- `DELETE /api/userrequests/{id}` - Talep sil

### UserFavorites
- `GET /api/userfavorites?userId={id}&tip={tip}` - Favorileri getir
- `POST /api/userfavorites` - Favori ekle
- `DELETE /api/userfavorites/{id}` - Favori sil
- `DELETE /api/userfavorites/by-identifier?userId={id}&title={title}&tip={tip}` - Identifier ile sil

### UserComments
- `GET /api/usercomments?cardId={cardId}` - Yorumları getir
- `POST /api/usercomments` - Yorum ekle
- `DELETE /api/usercomments/{id}` - Yorum sil

### UserServices
- `GET /api/userservices?userId={id}` - Servisleri getir
- `POST /api/userservices` - Servis ekle
- `DELETE /api/userservices/{id}` - Servis sil

## 📝 Sonraki Adımlar

1. Backend API URL'ini production URL'i ile değiştirin
2. CORS ayarlarını production için kısıtlayın
3. HTTPS kullanın
4. Error logging ekleyin (ör: Serilog)
5. Rate limiting ekleyin
6. Cache stratejisi ekleyin (Flutter tarafında)

