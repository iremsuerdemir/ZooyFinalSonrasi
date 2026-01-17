# Setup Checklist - Backend Migration

Bu checklist, backend entegrasyonunun kurulumunu adım adım kontrol etmenize yardımcı olur.

## ✅ Adım 1: SQL Migration Script

- [ ] SSMS'i açtım
- [ ] SQL Server'a bağlandım
- [ ] `ZoozyApi/Migrations/CreateUserDataTables.sql` dosyasını açtım
- [ ] Database adını kontrol ettim (varsayılan: `ZoozyApi`)
- [ ] Script'i çalıştırdım (`F5`)
- [ ] "All tables created successfully!" mesajını gördüm
- [ ] Tabloları kontrol ettim:
  - [ ] `UserRequests` tablosu var
  - [ ] `UserFavorites` tablosu var
  - [ ] `UserComments` tablosu var
  - [ ] `UserServices` tablosu var

**Kontrol Sorgusu:**
```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('UserRequests', 'UserFavorites', 'UserComments', 'UserServices');
```

## ✅ Adım 2: Backend API Yapılandırması

- [ ] Backend projesini açtım (`ZoozyApi` klasörü)
- [ ] `appsettings.json` dosyasındaki connection string'i kontrol ettim
- [ ] Backend'i çalıştırdım (`dotnet run`)
- [ ] Backend'in çalıştığını doğruladım:
  - [ ] Swagger UI açılıyor (`http://localhost:5001/swagger` veya `https://localhost:5002/swagger`)
  - [ ] API endpoint'leri görünüyor:
    - [ ] `/api/userrequests`
    - [ ] `/api/userfavorites`
    - [ ] `/api/usercomments`
    - [ ] `/api/userservices`

## ✅ Adım 3: Flutter URL Yapılandırması

- [ ] `lib/config/api_config.dart` dosyasını kontrol ettim
- [ ] Development için doğru URL ayarlandı:
  - [ ] `devBaseUrl` doğru IP adresini gösteriyor
  - [ ] Port numarası doğru (varsayılan: 5001)
- [ ] Production için hazırlık yaptım:
  - [ ] `isProduction = false` (development için)
  - [ ] `prodBaseUrl` production URL'i ile güncellenecek (şimdilik placeholder)

**Önemli:** Flutter uygulaması ile backend aynı network'te olmalı!

## ✅ Adım 4: Flutter Uygulaması Test

### 4.1. Uygulama Başlatma
- [ ] Flutter uygulamasını çalıştırdım
- [ ] Uygulama hatasız açıldı
- [ ] Login ekranı görünüyor

### 4.2. Login Test
- [ ] Mevcut bir kullanıcı ile login yaptım
- [ ] Veya yeni kullanıcı kaydı yaptım
- [ ] Login başarılı oldu
- [ ] Ana ekrana yönlendirildim

### 4.3. Network Bağlantısı Test
- [ ] Flutter DevTools'u açtım (`flutter pub global activate devtools` sonra `flutter pub global run devtools`)
- [ ] Network sekmesini açtım
- [ ] Bir API çağrısı yaptım (örn: Requests Screen'e gittim)
- [ ] HTTP request'lerin gittiğini gördüm
- [ ] Response'ları kontrol ettim

## ✅ Adım 5: CRUD İşlemleri Test

Detaylı test için `TEST_GUIDE.md` dosyasına bakın. Burada kısa bir özet:

### Requests
- [ ] Yeni talep oluşturuldu
- [ ] Talepler listelendi
- [ ] Talep silindi

### Favorites
- [ ] Favori eklendi (Moments)
- [ ] Favori eklendi (Caregiver)
- [ ] Favoriler listelendi
- [ ] Favoriden çıkarıldı

### Comments
- [ ] Yorum eklendi (Moments)
- [ ] Yorum eklendi (Caregiver)
- [ ] Yorumlar listelendi

### Services
- [ ] Hizmet eklendi
- [ ] Hizmetler listelendi
- [ ] Hizmet silindi

## ✅ Adım 6: Database Doğrulama

- [ ] SSMS'te database'e bağlandım
- [ ] Test sorgularını çalıştırdım:

```sql
-- Tüm verileri kontrol et
SELECT COUNT(*) as RequestCount FROM UserRequests;
SELECT COUNT(*) as FavoriteCount FROM UserFavorites;
SELECT COUNT(*) as CommentCount FROM UserComments;
SELECT COUNT(*) as ServiceCount FROM UserServices;
```

- [ ] Verilerin kaydedildiğini doğruladım
- [ ] Verilerin doğru formatta olduğunu kontrol ettim

## ✅ Adım 7: Hata Kontrolü

- [ ] Backend console'da hata yok
- [ ] Flutter console'da hata yok
- [ ] Network request'lerde hata yok
- [ ] Database constraint hataları yok

## 🎯 Production Deployment Hazırlığı

Production'a geçmeden önce:

- [ ] `lib/config/api_config.dart` → `isProduction = true`
- [ ] `prodBaseUrl` production API URL'i ile güncellendi
- [ ] CORS ayarları production için güncellendi
- [ ] HTTPS sertifikası ayarlandı
- [ ] Database connection string production için güncellendi
- [ ] Logging ve error tracking eklendi

## 📝 Notlar

- Tüm servisler `lib/config/api_config.dart` üzerinden yönetiliyor
- Development ve Production arasında geçiş için sadece `isProduction` flag'ini değiştirin
- SQL migration script `IF NOT EXISTS` kullanıyor, güvenle tekrar çalıştırılabilir
- Tüm HTTP servisler error handling ile korumalı

## 🆘 Yardım

Sorun yaşarsanız:
1. `TEST_GUIDE.md` dosyasındaki "Yaygın Hatalar ve Çözümleri" bölümüne bakın
2. Backend console loglarını kontrol edin
3. Flutter DevTools Network sekmesini kontrol edin
4. Database'deki verileri kontrol edin

