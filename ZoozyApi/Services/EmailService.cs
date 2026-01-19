using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ZoozyApi.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Şifre sıfırlama linki gönder (Token tabanlı - YENİ)
        /// </summary>
        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string resetToken, string displayName, string resetUrl)
        {
            try
            {
                // Email ayarlarını al
                var smtpUsername = _configuration["EmailSettings:SmtpUsername"];
                var smtpPassword = _configuration["EmailSettings:SmtpPassword"];
                var fromEmail = _configuration["EmailSettings:FromEmail"] ?? smtpUsername;
                var fromName = _configuration["EmailSettings:FromName"] ?? "Zoozy";

                // Eğer email ayarları yoksa, log yaz ve false döndür
                if (string.IsNullOrWhiteSpace(smtpUsername) || string.IsNullOrWhiteSpace(smtpPassword))
                {
                    _logger.LogWarning("Email ayarları yapılandırılmamış. SmtpUsername ve SmtpPassword gereklidir. Email gönderilemedi: {Email}", toEmail);
                    return false;
                }

                // Email adresinden otomatik SMTP ayarlarını belirle
                var (smtpHost, smtpPort, securityOption) = GetSmtpSettings(smtpUsername);
                
                // Manuel ayarlar varsa onları kullan (öncelikli)
                var manualHost = _configuration["EmailSettings:SmtpHost"];
                var manualPort = _configuration["EmailSettings:SmtpPort"];
                
                if (!string.IsNullOrWhiteSpace(manualHost))
                    smtpHost = manualHost;
                if (!string.IsNullOrWhiteSpace(manualPort) && int.TryParse(manualPort, out var port))
                    smtpPort = port;

                _logger.LogInformation("SMTP ayarları: Host={Host}, Port={Port}, Email={Email}", smtpHost, smtpPort, smtpUsername);

                // Email mesajı oluştur
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(fromName, fromEmail));
                message.To.Add(new MailboxAddress(displayName ?? "Kullanıcı", toEmail));
                message.Subject = "Zoozy - Şifre Sıfırlama";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #9C27B0 0%, #B39DDB 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
        .button {{ background: #9C27B0; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; font-weight: bold; }}
        .button:hover {{ background: #7B1FA2; }}
        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
        .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 Zoozy</h1>
            <p>Şifre Sıfırlama</p>
        </div>
        <div class='content'>
            <p>Merhaba {displayName ?? "Kullanıcı"},</p>
            <p>Şifre sıfırlama talebiniz alınmıştır. Yeni şifrenizi belirlemek için aşağıdaki butona tıklayın:</p>
            <div style='text-align: center;'>
                <a href='{resetUrl}' class='button'>Şifremi Sıfırla</a>
            </div>
            <div class='warning'>
                <strong>⚠️ Önemli:</strong> Bu link 1 saat içinde geçerlidir. Eğer bu talebi siz yapmadıysanız, lütfen bu e-postayı görmezden gelin.
            </div>
            <p>Eğer buton çalışmıyorsa, aşağıdaki linki tarayıcınıza kopyalayıp yapıştırabilirsiniz:</p>
            <p style='word-break: break-all; color: #9C27B0;'>{resetUrl}</p>
            <p>İyi günler dileriz,<br><strong>Zoozy Ekibi</strong></p>
        </div>
        <div class='footer'>
            <p>Bu bir otomatik e-postadır. Lütfen bu e-postaya yanıt vermeyin.</p>
        </div>
    </div>
</body>
</html>",
                    TextBody = $@"
Merhaba {displayName ?? "Kullanıcı"},

Şifre sıfırlama talebiniz alınmıştır. Yeni şifrenizi belirlemek için aşağıdaki linke tıklayın:

{resetUrl}

Bu link 1 saat içinde geçerlidir. Eğer bu talebi siz yapmadıysanız, lütfen bu e-postayı görmezden gelin.

İyi günler dileriz,
Zoozy Ekibi
"
                };

                message.Body = bodyBuilder.ToMessageBody();

                // SMTP ile email gönder
                using var client = new SmtpClient();
                
                try
                {
                    await client.ConnectAsync(smtpHost, smtpPort, securityOption);
                    await client.AuthenticateAsync(smtpUsername, smtpPassword);
                    await client.SendAsync(message);
                    await client.DisconnectAsync(true);
                }
                catch (Exception smtpEx)
                {
                    // Eğer StartTls başarısız olursa, SSL dene (bazı sunucular için)
                    if (securityOption == SecureSocketOptions.StartTls)
                    {
                        _logger.LogWarning("StartTls başarısız, SSL deneniyor: {Error}", smtpEx.Message);
                        await client.DisconnectAsync(false);
                        await client.ConnectAsync(smtpHost, smtpPort == 587 ? 465 : smtpPort, SecureSocketOptions.SslOnConnect);
                        await client.AuthenticateAsync(smtpUsername, smtpPassword);
                        await client.SendAsync(message);
                        await client.DisconnectAsync(true);
                    }
                    else
                    {
                        throw;
                    }
                }

                _logger.LogInformation("Şifre sıfırlama linki başarıyla gönderildi: {Email}", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Email gönderme hatası: {Email}", toEmail);
                return false;
            }
        }

        /// <summary>
        /// Email adresinden domain'i çıkarır ve SMTP ayarlarını otomatik belirler
        /// </summary>
        private (string Host, int Port, SecureSocketOptions Security) GetSmtpSettings(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return ("smtp.gmail.com", 587, SecureSocketOptions.StartTls);

            var domain = email.Split('@').LastOrDefault()?.ToLower() ?? "";

            return domain switch
            {
                // Gmail
                "gmail.com" => ("smtp.gmail.com", 587, SecureSocketOptions.StartTls),
                
                // Microsoft (Hotmail, Outlook, Live, MSN)
                "hotmail.com" or "outlook.com" or "live.com" or "msn.com" or "hotmail.co.uk" or "outlook.co.uk" 
                    => ("smtp-mail.outlook.com", 587, SecureSocketOptions.StartTls),
                
                // Yahoo
                "yahoo.com" or "yahoo.co.uk" or "yahoo.fr" or "yahoo.de" or "yahoo.es" or "yahoo.it" 
                    => ("smtp.mail.yahoo.com", 587, SecureSocketOptions.StartTls),
                
                // Yandex
                "yandex.com" or "yandex.ru" => ("smtp.yandex.com", 465, SecureSocketOptions.SslOnConnect),
                
                // Zoho
                "zoho.com" or "zoho.eu" => ("smtp.zoho.com", 587, SecureSocketOptions.StartTls),
                
                // ProtonMail
                "protonmail.com" or "proton.me" => ("127.0.0.1", 1025, SecureSocketOptions.None), // SMTP Bridge gerekli
                
                // Varsayılan (özel domain veya bilinmeyen)
                _ => ("smtp.gmail.com", 587, SecureSocketOptions.StartTls)
            };
        }

        public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string newPassword, string displayName)
        {
            try
            {
                // Email ayarlarını al
                var smtpUsername = _configuration["EmailSettings:SmtpUsername"];
                var smtpPassword = _configuration["EmailSettings:SmtpPassword"];
                var fromEmail = _configuration["EmailSettings:FromEmail"] ?? smtpUsername;
                var fromName = _configuration["EmailSettings:FromName"] ?? "Zoozy";

                // Eğer email ayarları yoksa, log yaz ve false döndür
                if (string.IsNullOrWhiteSpace(smtpUsername) || string.IsNullOrWhiteSpace(smtpPassword))
                {
                    _logger.LogWarning("Email ayarları yapılandırılmamış. SmtpUsername ve SmtpPassword gereklidir. Email gönderilemedi: {Email}", toEmail);
                    return false;
                }

                // Email adresinden otomatik SMTP ayarlarını belirle
                var (smtpHost, smtpPort, securityOption) = GetSmtpSettings(smtpUsername);
                
                // Manuel ayarlar varsa onları kullan (öncelikli)
                var manualHost = _configuration["EmailSettings:SmtpHost"];
                var manualPort = _configuration["EmailSettings:SmtpPort"];
                
                if (!string.IsNullOrWhiteSpace(manualHost))
                    smtpHost = manualHost;
                if (!string.IsNullOrWhiteSpace(manualPort) && int.TryParse(manualPort, out var port))
                    smtpPort = port;

                _logger.LogInformation("SMTP ayarları: Host={Host}, Port={Port}, Email={Email}", smtpHost, smtpPort, smtpUsername);

                // Email mesajı oluştur
                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(fromName, fromEmail));
                message.To.Add(new MailboxAddress(displayName ?? "Kullanıcı", toEmail));
                message.Subject = "Zoozy - Şifre Sıfırlama";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #9C27B0 0%, #B39DDB 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
        .password-box {{ background: white; border: 2px solid #9C27B0; border-radius: 5px; padding: 15px; margin: 20px 0; text-align: center; font-size: 18px; font-weight: bold; color: #9C27B0; }}
        .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🐾 Zoozy</h1>
            <p>Şifre Sıfırlama</p>
        </div>
        <div class='content'>
            <p>Merhaba {displayName ?? "Kullanıcı"},</p>
            <p>Şifre sıfırlama talebiniz alınmıştır. Yeni şifreniz aşağıdadır:</p>
            <div class='password-box'>
                {newPassword}
            </div>
            <p>Güvenliğiniz için lütfen bu şifreyi kimseyle paylaşmayın ve giriş yaptıktan sonra şifrenizi değiştirmenizi öneririz.</p>
            <p>Eğer bu talebi siz yapmadıysanız, lütfen hemen bizimle iletişime geçin.</p>
            <p>İyi günler dileriz,<br><strong>Zoozy Ekibi</strong></p>
        </div>
        <div class='footer'>
            <p>Bu bir otomatik e-postadır. Lütfen bu e-postaya yanıt vermeyin.</p>
        </div>
    </div>
</body>
</html>",
                    TextBody = $@"
Merhaba {displayName ?? "Kullanıcı"},

Şifre sıfırlama talebiniz alınmıştır. Yeni şifreniz:

{newPassword}

Güvenliğiniz için lütfen bu şifreyi kimseyle paylaşmayın ve giriş yaptıktan sonra şifrenizi değiştirmenizi öneririz.

Eğer bu talebi siz yapmadıysanız, lütfen hemen bizimle iletişime geçin.

İyi günler dileriz,
Zoozy Ekibi
"
                };

                message.Body = bodyBuilder.ToMessageBody();

                // SMTP ile email gönder
                using var client = new SmtpClient();
                
                try
                {
                    await client.ConnectAsync(smtpHost, smtpPort, securityOption);
                    await client.AuthenticateAsync(smtpUsername, smtpPassword);
                    await client.SendAsync(message);
                    await client.DisconnectAsync(true);
                }
                catch (Exception smtpEx)
                {
                    // Eğer StartTls başarısız olursa, SSL dene (bazı sunucular için)
                    if (securityOption == SecureSocketOptions.StartTls)
                    {
                        _logger.LogWarning("StartTls başarısız, SSL deneniyor: {Error}", smtpEx.Message);
                        await client.DisconnectAsync(false);
                        await client.ConnectAsync(smtpHost, smtpPort == 587 ? 465 : smtpPort, SecureSocketOptions.SslOnConnect);
                        await client.AuthenticateAsync(smtpUsername, smtpPassword);
                        await client.SendAsync(message);
                        await client.DisconnectAsync(true);
                    }
                    else
                    {
                        throw;
                    }
                }

                _logger.LogInformation("Şifre sıfırlama emaili başarıyla gönderildi: {Email}", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Email gönderme hatası: {Email}", toEmail);
                return false;
            }
        }
    }
}

