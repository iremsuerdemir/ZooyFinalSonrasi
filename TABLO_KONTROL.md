# Tablo Kontrol Rehberi

## 🔍 Tablolar Oluşturuldu mu Kontrol Etme

### Yöntem 1: Hızlı Kontrol (SSMS'te Çalıştırın)

1. **SSMS'i açın** ve SQL Server'a bağlanın
2. Yeni Query penceresi açın (`Ctrl + N`)
3. Şu sorguyu çalıştırın:

```sql
USE [ZoozyApi]; -- Database adınızı yazın
GO

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('UserRequests', 'UserFavorites', 'UserComments', 'UserServices');
```

**Sonuç:**
- ✅ **4 satır görüyorsanız:** Tüm tablolar oluşturulmuş!
- ❌ **0 satır görüyorsanız:** Tablolar henüz oluşturulmamış, migration script'ini çalıştırın

### Yöntem 2: Object Explorer'dan Kontrol

1. SSMS'te sol tarafta **Object Explorer**'ı açın
2. **Databases** → **ZoozyApi** → **Tables** klasörünü açın
3. Şu tabloları arayın:
   - ✅ `dbo.UserRequests`
   - ✅ `dbo.UserFavorites`
   - ✅ `dbo.UserComments`
   - ✅ `dbo.UserServices`

### Yöntem 3: Detaylı Kontrol Sorgusu

`ZoozyApi/Migrations/CheckTables.sql` dosyasını SSMS'te çalıştırın.

## ⚠️ Eğer Tablolar Yoksa

1. `ZoozyApi/Migrations/CreateUserDataTables.sql` dosyasını açın
2. Database adını kontrol edin (varsayılan: `ZoozyApi`)
3. Script'in tamamını seçin ve `F5` ile çalıştırın
4. "All tables created successfully!" mesajını görmelisiniz

## 🔧 Sorun Giderme

### "Database 'ZoozyApi' does not exist" hatası
**Çözüm:** Database adını doğru yazdığınızdan emin olun veya önce database'i oluşturun:
```sql
CREATE DATABASE ZoozyApi;
GO
```

### "Foreign key constraint" hatası
**Sebep:** Users tablosu yok
**Çözüm:** Önce auth migration'larını çalıştırın (Users tablosu oluşturulmalı)

### Tablolar var ama çalışmıyor
**Kontrol:**
```sql
-- Tablo yapısını kontrol edin
EXEC sp_help 'UserRequests';
EXEC sp_help 'UserFavorites';
EXEC sp_help 'UserComments';
EXEC sp_help 'UserServices';
```

## ✅ Başarılı Olursa

Tablolar oluşturulduktan sonra şu verileri görebilirsiniz:

```sql
-- Tablo kayıt sayılarını kontrol edin (başlangıçta 0 olmalı)
SELECT 
    'UserRequests' as Tablo, COUNT(*) as KayitSayisi FROM UserRequests
UNION ALL
SELECT 'UserFavorites', COUNT(*) FROM UserFavorites
UNION ALL
SELECT 'UserComments', COUNT(*) FROM UserComments
UNION ALL
SELECT 'UserServices', COUNT(*) FROM UserServices;
```

Tüm tablolar **0** kayıt göstermeli (henüz veri eklenmediyse).

