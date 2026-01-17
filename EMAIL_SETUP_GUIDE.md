# Email Yapılandırma Kılavuzu

Şifre sıfırlama özelliğinin çalışması için email ayarlarını yapılandırmanız gerekmektedir.

## ✨ Otomatik SMTP Algılama

Sistem, email adresinizden otomatik olarak doğru SMTP ayarlarını algılar! Gmail, Hotmail, Outlook, Yahoo ve diğer popüler sağlayıcılar için otomatik yapılandırma yapılır.

**Desteklenen Email Sağlayıcıları:**
- ✅ Gmail (gmail.com)
- ✅ Hotmail (hotmail.com)
- ✅ Outlook (outlook.com, live.com, msn.com)
- ✅ Yahoo (yahoo.com, yahoo.co.uk, yahoo.fr, vb.)
- ✅ Yandex (yandex.com, yandex.ru)
- ✅ Zoho (zoho.com, zoho.eu)
- ✅ Özel domain'ler (varsayılan Gmail ayarları kullanılır)

## Adımlar

### 1. Email Ayarlarını Yapılandırma

`ZoozyApi/appsettings.json` dosyasını açın ve `EmailSettings` bölümünü doldurun:

```json
{
  "EmailSettings": {
    "SmtpUsername": "your-email@gmail.com",
    "SmtpPassword": "your-password",
    "FromEmail": "your-email@gmail.com",
    "FromName": "Zoozy"
  }
}
```

**Not:** `SmtpHost` ve `SmtpPort` otomatik algılanır, manuel ayarlamaya gerek yoktur!

### 2. Gmail Kullanıyorsanız

Gmail için özel bir "App Password" oluşturmanız gerekir:

1. Google Hesabınıza giriş yapın
2. [Google Account Security](https://myaccount.google.com/security) sayfasına gidin
3. "2-Step Verification" (2 Adımlı Doğrulama) açık olmalı
4. [App Passwords](https://myaccount.google.com/apppasswords) sayfasına gidin
5. "Select app" → "Mail" seçin
6. "Select device" → "Other (Custom name)" → "Zoozy API" yazın
7. "Generate" butonuna tıklayın
8. Oluşturulan 16 karakterlik şifreyi `SmtpPassword` alanına yapıştırın

**Önemli:** Normal Gmail şifreniz çalışmaz, mutlaka App Password kullanmalısınız!

### 3. Hotmail/Outlook Kullanıyorsanız

Hotmail ve Outlook için normal şifrenizi kullanabilirsiniz:

```json
{
  "EmailSettings": {
    "SmtpUsername": "your-email@hotmail.com",
    "SmtpPassword": "your-normal-password",
    "FromEmail": "your-email@hotmail.com",
    "FromName": "Zoozy"
  }
}
```

**Not:** Sistem otomatik olarak `smtp-mail.outlook.com` kullanacaktır.

### 4. Yahoo Kullanıyorsanız

Yahoo için App Password gerekebilir:

1. [Yahoo Account Security](https://login.yahoo.com/account/security) sayfasına gidin
2. "Generate app password" seçeneğini bulun
3. Yeni bir app password oluşturun
4. Oluşturulan şifreyi `SmtpPassword` alanına yapıştırın

### 5. Özel SMTP Sunucusu (İsteğe Bağlı)

Eğer özel bir SMTP sunucusu kullanmak istiyorsanız, manuel ayarlar ekleyebilirsiniz:

```json
{
  "EmailSettings": {
    "SmtpHost": "smtp.yourdomain.com",
    "SmtpPort": "587",
    "SmtpUsername": "your-email@yourdomain.com",
    "SmtpPassword": "your-password",
    "FromEmail": "your-email@yourdomain.com",
    "FromName": "Zoozy"
  }
}
```

### 6. Güvenlik İçin Ortam Değişkenleri (Önerilen)

Şifreleri `appsettings.json` dosyasında saklamak yerine ortam değişkenleri kullanabilirsiniz:

**Windows:**
```cmd
set ZOOZY_EmailSettings__SmtpUsername=your-email@gmail.com
set ZOOZY_EmailSettings__SmtpPassword=your-app-password
```

**Linux/Mac:**
```bash
export ZOOZY_EmailSettings__SmtpUsername=your-email@gmail.com
export ZOOZY_EmailSettings__SmtpPassword=your-app-password
```

**appsettings.json'da:**
```json
{
  "EmailSettings": {
    "FromName": "Zoozy"
  }
}
```

### 7. Test Etme

Email ayarlarını yapılandırdıktan sonra:

1. Backend API'yi çalıştırın
2. Şifre sıfırlama ekranından bir email adresi girin
3. Email'inizin gelen kutusunu kontrol edin
4. Spam klasörünü de kontrol edin

### 8. Sorun Giderme

**Email gelmiyorsa:**

1. `appsettings.json` dosyasındaki ayarları kontrol edin
2. Backend loglarını kontrol edin (console çıktısı)
3. Gmail kullanıyorsanız App Password kullandığınızdan emin olun
4. Hotmail/Outlook kullanıyorsanız normal şifrenizi kullanın
5. Firewall veya güvenlik duvarı SMTP portunu engelliyor olabilir
6. Email sağlayıcınızın SMTP ayarlarını doğrulayın
7. Spam klasörünü kontrol edin

**Log mesajları:**
- "Email ayarları yapılandırılmamış" → `SmtpUsername` veya `SmtpPassword` boş
- "SMTP ayarları: Host=..." → Sistem hangi SMTP sunucusunu kullandığını gösterir
- "Email gönderme hatası" → SMTP bağlantı sorunu, log detaylarına bakın
- "StartTls başarısız, SSL deneniyor" → Sistem otomatik olarak alternatif bağlantı dener

**Yaygın Hatalar:**

| Hata | Çözüm |
|------|-------|
| "Authentication failed" | Şifre yanlış veya Gmail için App Password kullanılmamış |
| "Connection timeout" | Firewall SMTP portunu engelliyor |
| "StartTls başarısız" | Sistem otomatik olarak SSL'e geçer, bekleyin |

### 9. Production Ortamı

Production ortamında:

- Email şifrelerini **asla** kod deposuna commit etmeyin
- Ortam değişkenleri veya Azure Key Vault gibi güvenli depolama kullanın
- Email gönderim hatalarını loglayın ve izleyin
- Rate limiting ekleyin (çok fazla email gönderimini önlemek için)

## Örnek Yapılandırmalar

### Gmail Örneği
```json
{
  "EmailSettings": {
    "SmtpUsername": "zoozy.app@gmail.com",
    "SmtpPassword": "abcd efgh ijkl mnop",
    "FromEmail": "zoozy.app@gmail.com",
    "FromName": "Zoozy Pet Care"
  }
}
```
*Not: SmtpHost ve SmtpPort otomatik olarak `smtp.gmail.com:587` olarak ayarlanır*

### Hotmail/Outlook Örneği
```json
{
  "EmailSettings": {
    "SmtpUsername": "zoozy@hotmail.com",
    "SmtpPassword": "your-normal-password",
    "FromEmail": "zoozy@hotmail.com",
    "FromName": "Zoozy Pet Care"
  }
}
```
*Not: SmtpHost ve SmtpPort otomatik olarak `smtp-mail.outlook.com:587` olarak ayarlanır*

### Yahoo Örneği
```json
{
  "EmailSettings": {
    "SmtpUsername": "zoozy@yahoo.com",
    "SmtpPassword": "your-app-password",
    "FromEmail": "zoozy@yahoo.com",
    "FromName": "Zoozy Pet Care"
  }
}
```
*Not: SmtpHost ve SmtpPort otomatik olarak `smtp.mail.yahoo.com:587` olarak ayarlanır*

## Otomatik Algılama Nasıl Çalışır?

Sistem, `SmtpUsername` alanındaki email adresinden domain'i çıkarır ve aşağıdaki tabloya göre otomatik SMTP ayarlarını yapar:

| Email Domain | SMTP Host | Port | Güvenlik |
|--------------|-----------|------|----------|
| gmail.com | smtp.gmail.com | 587 | StartTls |
| hotmail.com, outlook.com, live.com | smtp-mail.outlook.com | 587 | StartTls |
| yahoo.com, yahoo.co.uk, vb. | smtp.mail.yahoo.com | 587 | StartTls |
| yandex.com, yandex.ru | smtp.yandex.com | 465 | SSL |
| zoho.com, zoho.eu | smtp.zoho.com | 587 | StartTls |
| Diğerleri | smtp.gmail.com | 587 | StartTls |

Bu sayede sadece email adresinizi ve şifrenizi girmeniz yeterlidir!

