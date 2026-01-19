# Test Rehberi - Backend Entegrasyonu

Bu rehber, tüm CRUD işlemlerinin nasıl test edileceğini açıklar.

## 🚀 Ön Hazırlık

### 1. SQL Migration Script Çalıştırma

**SSMS (SQL Server Management Studio) ile:**

1. SSMS'i açın ve SQL Server'a bağlanın
2. Yeni Query penceresi açın (`Ctrl + N`)
3. `ZoozyApi/Migrations/CreateUserDataTables.sql` dosyasını açın
4. Database adını kontrol edin (varsayılan: `ZoozyApi`)
5. Script'i çalıştırın (`F5` veya Execute butonu)
6. "All tables created successfully!" mesajını görmelisiniz

**Alternatif: Entity Framework Migration**

```bash
cd ZoozyApi
dotnet ef migrations add AddUserDataTables
dotnet ef database update
```

### 2. Backend API'yi Başlatma

```bash
cd ZoozyApi
dotnet run
```

Backend `http://localhost:5001` veya `https://localhost:5002` adresinde çalışmalı.

### 3. Backend URL Yapılandırması

`lib/config/api_config.dart` dosyasında:
- Development için: `devBaseUrl` kullanılır (varsayılan: `http://192.168.34.149:5001`)
- Production için: `isProduction = true` yapın ve `prodBaseUrl`'i ayarlayın

## 🧪 Test Senaryoları

### Test 1: User Requests (Kullanıcı Talepleri)

#### 1.1. Yeni Talep Oluşturma
1. Flutter uygulamasını başlatın
2. Login yapın (kullanıcı olmalı)
3. **Requests Screen** → "TALEP OLUŞTURUN" butonuna tıklayın
4. Hizmet seçin (örn: Pansiyon)
5. Pet bilgilerini doldurun
6. Tarih seçin
7. Talep oluşturun

**Beklenen:** 
- Talep başarıyla oluşturulmalı
- Requests Screen'de yeni talep görünmeli
- Backend'de `/api/userrequests` endpoint'ine POST request gitmeli

#### 1.2. Talepleri Listeleme
1. **Requests Screen**'e gidin
2. Sayfa yüklendiğinde talepler backend'den çekilmeli

**Beklenen:**
- Daha önce oluşturduğunuz talepler görünmeli
- Loading indicator gösterilmeli

#### 1.3. Talep Silme
1. **Requests Screen**'de bir talep kartında silme butonuna (çöp kutusu) tıklayın
2. Onaylayın

**Beklenen:**
- Talep listeden kalkmalı
- Backend'den silinmeli
- `DELETE /api/userrequests/{id}` çağrılmalı

### Test 2: User Favorites (Favoriler)

#### 2.1. Favori Ekleme - Moments
1. **Moments Screen**'e gidin
2. Bir post'ta kalp ikonuna tıklayın

**Beklenen:**
- Kalp kırmızı olmalı
- "Favorilere eklendi!" mesajı gösterilmeli
- Backend'e kaydedilmeli

#### 2.2. Favori Ekleme - Caregiver
1. **Explore Screen** veya **Backers List**'e gidin
2. Bir bakıcı kartında kalp ikonuna tıklayın

**Beklenen:**
- Kalp kırmızı olmalı
- Backend'e kaydedilmeli

#### 2.3. Favorileri Listeleme
1. **Profile Screen** → "Favorilerim" butonuna tıklayın
2. Veya **Explore/Moments Screen**'den favoriler sayfasına gidin

**Beklenen:**
- Eklediğiniz favoriler görünmeli
- Tip filtresi çalışmalı (caregiver, moments, explore)

#### 2.4. Favoriden Çıkarma
1. Favoriler sayfasında bir favori kartında kalp ikonuna tıklayın

**Beklenen:**
- Favori listeden kalkmalı
- Backend'den silinmeli

### Test 3: User Comments (Yorumlar)

#### 3.1. Yorum Ekleme - Moments
1. **Moments Screen**'de bir post'ta yorum ikonuna tıklayın
2. "Yorum Ekle" butonuna tıklayın
3. Yıldız değerlendirmesi seçin
4. Yorum yazın
5. "Yorum Ekle" butonuna tıklayın

**Beklenen:**
- Yorum eklenmeli
- Post'un altında görünmeli
- Backend'e kaydedilmeli

#### 3.2. Yorum Ekleme - Caregiver Profile
1. Bir bakıcı profil sayfasına gidin
2. "Yorumlar" bölümünde yorum ekleyin

**Beklenen:**
- Yorum eklenmeli
- Profil sayfasında görünmeli
- Backend'e kaydedilmeli

#### 3.3. Yorumları Listeleme
1. Yorumları içeren bir sayfaya gidin (Moments veya Caregiver Profile)
2. Yorumlar otomatik yüklenmeli

**Beklenen:**
- Önceden eklenen yorumlar görünmeli
- Yorum sayısı doğru gösterilmeli

### Test 4: User Services (Hizmet Kartları)

#### 4.1. Hizmet Ekleme (Profile Screen)
1. **Profile Screen**'e gidin
2. "Evcil Hayvan Hizmeti Ekle" butonuna tıklayın
3. Anlaşmaları onaylayın
4. Hizmet seçin (örn: Evcil Hayvan Pansiyonu)
5. Hizmet bilgilerini doldurun (açıklama, fiyat, adres)
6. Hizmeti kaydedin

**Beklenen:**
- Hizmet Profile Screen'de kart olarak görünmeli
- Backend'e kaydedilmeli
- `POST /api/userservices` çağrılmalı

#### 4.2. Hizmetleri Listeleme
1. **Profile Screen**'e gidin

**Beklenen:**
- Daha önce eklediğiniz hizmetler görünmeli
- Hizmetler backend'den yüklenmeli

#### 4.3. Hizmet Silme
1. **Profile Screen**'de bir hizmet kartında silme butonuna (çöp kutusu) tıklayın
2. Onaylayın

**Beklenen:**
- Hizmet listeden kalkmalı
- Backend'den silinmeli
- `DELETE /api/userservices/{id}` çağrılmalı

## 🔍 Debugging ve Kontrol

### Backend Log Kontrolü

Backend console'unda şu logları görebilirsiniz:
- HTTP request logları
- Database operation logları
- Hata mesajları

### Database Kontrolü

SSMS'te şu sorguları çalıştırarak verileri kontrol edebilirsiniz:

```sql
-- Tüm talepler
SELECT * FROM UserRequests;

-- Tüm favoriler
SELECT * FROM UserFavorites;

-- Tüm yorumlar
SELECT * FROM UserComments;

-- Tüm hizmetler
SELECT * FROM UserServices;

-- Belirli kullanıcının verileri (UserId = 1 örneği)
SELECT * FROM UserRequests WHERE UserId = 1;
SELECT * FROM UserFavorites WHERE UserId = 1;
SELECT * FROM UserComments WHERE UserId = 1;
SELECT * FROM UserServices WHERE UserId = 1;
```

### Flutter Debug Console

Flutter uygulamasında şu logları görebilirsiniz:
- HTTP request/response logları
- Hata mesajları (eğer varsa)

## ⚠️ Yaygın Hatalar ve Çözümleri

### 1. "Connection refused" hatası
**Sebep:** Backend çalışmıyor veya URL yanlış
**Çözüm:**
- Backend'in çalıştığından emin olun
- `lib/config/api_config.dart` dosyasındaki URL'i kontrol edin
- Network bağlantısını kontrol edin

### 2. "User not found" hatası
**Sebep:** Login olmamış veya userId SharedPreferences'ta yok
**Çözüm:**
- Uygulamada login yapın
- SharedPreferences'ta `userId` olduğundan emin olun

### 3. "Foreign key constraint" hatası
**Sebep:** Users tablosunda ilgili kullanıcı yok
**Çözüm:**
- Önce kullanıcı kaydı yapın (login/register)
- Users tablosunda kullanıcının olduğundan emin olun

### 4. Veriler görünmüyor
**Sebep:** Backend'den veri çekilemiyor
**Çözüm:**
- Backend'in çalıştığını kontrol edin
- Network request'lerini kontrol edin (Flutter DevTools)
- Backend console loglarını kontrol edin

## ✅ Test Checklist

- [ ] SQL migration script çalıştırıldı
- [ ] Backend API çalışıyor
- [ ] Flutter uygulamasında login yapıldı
- [ ] User Request oluşturma çalışıyor
- [ ] User Request listeleme çalışıyor
- [ ] User Request silme çalışıyor
- [ ] Favori ekleme çalışıyor (Moments)
- [ ] Favori ekleme çalışıyor (Caregiver)
- [ ] Favori listeleme çalışıyor
- [ ] Favori silme çalışıyor
- [ ] Yorum ekleme çalışıyor (Moments)
- [ ] Yorum ekleme çalışıyor (Caregiver)
- [ ] Yorum listeleme çalışıyor
- [ ] Hizmet ekleme çalışıyor
- [ ] Hizmet listeleme çalışıyor
- [ ] Hizmet silme çalışıyor
- [ ] Database'de veriler kaydediliyor
- [ ] Production URL yapılandırması hazır

## 🎯 Sonraki Adımlar

1. **Production Deployment:**
   - `lib/config/api_config.dart` → `isProduction = true`
   - `prodBaseUrl`'i production API URL'i ile güncelleyin

2. **CORS Ayarları:**
   - Production'da CORS'u kısıtlayın (sadece izin verilen domain'ler)

3. **HTTPS:**
   - Production'da HTTPS kullanın

4. **Error Logging:**
   - Backend'de Serilog veya benzeri logging ekleyin
   - Flutter'da error tracking (Sentry, Firebase Crashlytics) ekleyin

5. **Performance:**
   - Database indexlerini optimize edin
   - Flutter tarafında caching ekleyin
   - Pagination ekleyin (çok fazla veri varsa)

