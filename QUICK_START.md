# 🚀 Hızlı Başlangıç - Backend Entegrasyonu

## 3 Adımda Başlayın

### 1️⃣ SQL Migration (5 dakika)

1. **SSMS'i açın** ve SQL Server'a bağlanın
2. `ZoozyApi/Migrations/CreateUserDataTables.sql` dosyasını açın
3. Database adını kontrol edin (varsayılan: `ZoozyApi`)
4. Script'i çalıştırın (`F5`)
5. ✅ "All tables created successfully!" mesajını görün

**Hızlı Kontrol:**
```sql
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('UserRequests', 'UserFavorites', 'UserComments', 'UserServices');
```

### 2️⃣ Backend URL Yapılandırması (2 dakika)

1. `lib/config/api_config.dart` dosyasını açın
2. Backend'iniz çalışıyorsa IP adresini kontrol edin:
   ```dart
   static const String devBaseUrl = 'http://192.168.34.149:5001'; // Kendi IP'nizi yazın
   ```
3. ✅ `isProduction = false` olduğundan emin olun

### 3️⃣ Backend'i Başlatın (1 dakika)

```bash
cd ZoozyApi
dotnet run
```

✅ Backend çalışıyor mu kontrol edin: `http://localhost:5001/swagger`

## 🧪 Hızlı Test

1. **Flutter uygulamasını başlatın**
2. **Login yapın**
3. **Requests Screen** → Yeni talep oluşturun
4. ✅ Talep görünüyorsa başarılı!

## 📚 Detaylı Dokümantasyon

- **Test Rehberi:** `TEST_GUIDE.md`
- **Setup Checklist:** `SETUP_CHECKLIST.md`
- **Migration Rehberi:** `BACKEND_MIGRATION_GUIDE.md`

## ❓ Sorun mu var?

`TEST_GUIDE.md` dosyasındaki "Yaygın Hatalar ve Çözümleri" bölümüne bakın.
