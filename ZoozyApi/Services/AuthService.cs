using ZoozyApi.Data;
using ZoozyApi.Dtos;
using ZoozyApi.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using BCrypt.Net;

namespace ZoozyApi.Services
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> LoginAsync(LoginRequest request);
        Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request);
        Task<UserDto?> GetUserByIdAsync(int id);
        Task<UserDto?> GetUserByEmailAsync(string email);
        Task<ResetPasswordResponse> ResetPasswordAsync(string email);
        Task<ConfirmResetPasswordResponse> ConfirmResetPasswordAsync(string token, string newPassword);
        Task<bool> UpdateUserAgreementsAsync(int userId, bool termsAccepted, bool privacyAccepted);
    }

    public class AuthService : IAuthService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<AuthService> _logger;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;

        public AuthService(AppDbContext context, ILogger<AuthService> logger, IEmailService emailService, IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _emailService = emailService;
            _configuration = configuration;
        }

        /// <summary>
        /// Email ve şifre ile yeni kullanıcı kaydı
        /// </summary>
        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            try
            {
                // Validasyon
                if (string.IsNullOrWhiteSpace(request.Email) || 
                    string.IsNullOrWhiteSpace(request.Password) ||
                    string.IsNullOrWhiteSpace(request.DisplayName))
                {
                    return new AuthResponse 
                    { 
                        Success = false, 
                        Message = "Email, şifre ve ad gereklidir." 
                    };
                }

                // Email zaten var mı?
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());

                if (existingUser != null)
                {
                    // Eğer mevcut kullanıcı Google ile kayıtlıysa özel mesaj ver
                    if (string.Equals(existingUser.Provider, "google", StringComparison.OrdinalIgnoreCase))
                    {
                        return new AuthResponse 
                        { 
                            Success = false, 
                            Message = "Bu e-posta adresi Google hesabı ile kayıtlıdır. Lütfen Google ile Giriş Yap seçeneğini kullanın." 
                        };
                    }

                    return new AuthResponse 
                    { 
                        Success = false, 
                        Message = "Bu email adresi zaten kayıtlı." 
                    };
                }

                // Şifre hash'le (BCrypt) - Trim yaparak tutarlılık sağla
                string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password.Trim());

                var newUser = new User
                {
                    Email = request.Email.ToLower(),
                    PasswordHash = passwordHash,
                    DisplayName = request.DisplayName,
                    Provider = "local",
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Yeni kullanıcı kaydı başarılı: {newUser.Email}");

                return new AuthResponse
                {
                    Success = true,
                    Message = "Kayıt başarılı!",
                    User = MapUserToDto(newUser)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Kayıt hatası: {ex.Message}");
                return new AuthResponse 
                { 
                    Success = false, 
                    Message = "Kayıt işlemi sırasında hata oluştu." 
                };
            }
        }

        /// <summary>
        /// Email ve şifre ile login
        /// </summary>
 public async Task<AuthResponse> LoginAsync(LoginRequest request)
{
    try
    {
        if (string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return new AuthResponse
            {
                Success = false,
                Message = "Email ve şifre gereklidir."
            };
        }

        // 🔍 Email ile kullanıcıyı BUL (provider ayırmadan)
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());

        if (user == null)
        {
            return new AuthResponse
            {
                Success = false,
                Message = "Böyle bir hesap bulunmamaktadır. Hesap oluşturmak için kayıt oluşturun."
            };
        }

        if (!user.IsActive)
        {
            return new AuthResponse
            {
                Success = false,
                Message = "Hesabınız aktif değil."
            };
        }

        // 🔴 GOOGLE KULLANICI KONTROLÜ
        // Provider kontrolünü case-insensitive yapalım
        if (string.Equals(user.Provider, "google", StringComparison.OrdinalIgnoreCase))
        {
            return new AuthResponse
            {
                Success = false,
                Message = "Bu e-posta adresi Google hesabı ile bağlıdır. Lütfen şifre girmek yerine 'Google ile Giriş Yap' butonunu kullanın."
            };
        }

        // 🔐 Şifre doğrula (local kullanıcı)
        // PasswordHash null veya boş ise hata döndür
        if (string.IsNullOrEmpty(user.PasswordHash))
        {
            _logger.LogWarning($"User has no password hash: {user.Email}");
            return new AuthResponse
            {
                Success = false,
                Message = "Email veya şifre yanlış."
            };
        }

        // DEBUG LOG:
        _logger.LogWarning($"LOGIN ATTEMPT: User={user.Email}, InputPass={request.Password.Trim()}, StoredHash={user.PasswordHash}");

        bool isValidPassword = BCrypt.Net.BCrypt.Verify(
            request.Password.Trim(),
            user.PasswordHash
        );

        _logger.LogWarning($"VERIFY RESULT: {isValidPassword}");

        if (!isValidPassword)
        {
            return new AuthResponse
            {
                Success = false,
                Message = "Email veya şifre yanlış."
            };
        }

        user.UpdatedAt = DateTime.UtcNow;
        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        _logger.LogInformation($"Başarılı login: {user.Email}");

        return new AuthResponse
        {
            Success = true,
            Message = "Login başarılı!",
            User = MapUserToDto(user)
        };
    }
    catch (Exception ex)
    {
        _logger.LogError($"Login hatası: {ex.Message}");
        return new AuthResponse
        {
            Success = false,
            Message = "Login işlemi sırasında hata oluştu."
        };
    }
}


        /// <summary>
        /// Google Firebase UID ile login/register
        /// </summary>
        public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.FirebaseUid) || 
                    string.IsNullOrWhiteSpace(request.Email))
                {
                    return new AuthResponse 
                    { 
                        Success = false, 
                        Message = "FirebaseUid ve Email gereklidir." 
                    };
                }

                // PhotoUrl'ü normalize et: null veya sadece boşluk ise NULL kaydet
                string? normalizedPhotoUrl = null;
                if (!string.IsNullOrWhiteSpace(request.PhotoUrl))
                {
                    normalizedPhotoUrl = request.PhotoUrl!.Trim();
                }

                // Var mı kontrol et (FirebaseUid ile)
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.FirebaseUid == request.FirebaseUid);

                if (existingUser != null && existingUser.IsActive)
                {
                    existingUser.UpdatedAt = DateTime.UtcNow;
                    // Profil güncelleme
                    existingUser.DisplayName = request.DisplayName;
                    // Sadece geçerli bir PhotoUrl geldiyse güncelle, aksi halde eski resmi koru
                    if (normalizedPhotoUrl != null)
                    {
                        existingUser.PhotoUrl = normalizedPhotoUrl;
                    }

                    _context.Users.Update(existingUser);
                    await _context.SaveChangesAsync();

                    _logger.LogInformation($"Google login başarılı: {existingUser.Email}");

                    return new AuthResponse
                    {
                        Success = true,
                        Message = "Google login başarılı!",
                        User = MapUserToDto(existingUser)
                    };
                }

                // Email ile de kontrol et (yeni Google hesabı eski email ile)
                var emailUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower());

                if (emailUser != null)
                {
                    // Mevcut kullanıcıya Google uid bağla
                    emailUser.FirebaseUid = request.FirebaseUid;
                    emailUser.Provider = "google";
                    emailUser.DisplayName = request.DisplayName;
                    // Sadece geçerli bir PhotoUrl geldiyse güncelle
                    if (normalizedPhotoUrl != null)
                    {
                        emailUser.PhotoUrl = normalizedPhotoUrl;
                    }
                    emailUser.UpdatedAt = DateTime.UtcNow;

                    _context.Users.Update(emailUser);
                    await _context.SaveChangesAsync();

                    _logger.LogInformation($"Email kullanıcısına Google uid bağlandı: {emailUser.Email}");

                    return new AuthResponse
                    {
                        Success = true,
                        Message = "Google hesabı bağlandı!",
                        User = MapUserToDto(emailUser)
                    };
                }

                // Yeni Google kullanıcısı oluştur
                var newGoogleUser = new User
                {
                    FirebaseUid = request.FirebaseUid,
                    Email = request.Email.ToLower(),
                    DisplayName = request.DisplayName,
                    PhotoUrl = normalizedPhotoUrl,
                    Provider = "google",
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _context.Users.Add(newGoogleUser);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Yeni Google kullanıcısı oluşturuldu: {newGoogleUser.Email}");

                return new AuthResponse
                {
                    Success = true,
                    Message = "Google ile kayıt başarılı!",
                    User = MapUserToDto(newGoogleUser)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Google login hatası: {ex.Message}");
                return new AuthResponse 
                { 
                    Success = false, 
                    Message = "Google login sırasında hata oluştu." 
                };
            }
        }

        /// <summary>
        /// ID ile kullanıcı al
        /// </summary>
        public async Task<UserDto?> GetUserByIdAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            return user == null ? null : MapUserToDto(user);
        }

        /// <summary>
        /// Email ile kullanıcı al
        /// </summary>
        public async Task<UserDto?> GetUserByEmailAsync(string email)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
            return user == null ? null : MapUserToDto(user);
        }

        /// <summary>
        /// User entity'yi UserDto'ya dönüştür
        /// </summary>
        private UserDto MapUserToDto(User user)
        {
            return new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                PhotoUrl = user.PhotoUrl,
                Bio = user.Bio,
                Provider = user.Provider,
                FirebaseUid = user.FirebaseUid,
                CreatedAt = user.CreatedAt,
                TermsAccepted = user.TermsAccepted,
                PrivacyAccepted = user.PrivacyAccepted
            };
        }

        /// <summary>
        /// Şifre sıfırlama - token oluştur ve email'e link gönder
        /// </summary>
        public async Task<ResetPasswordResponse> ResetPasswordAsync(string email)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email))
                {
                    return new ResetPasswordResponse
                    {
                        Success = false,
                        Message = "Email gereklidir."
                    };
                }

                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());

                if (user == null)
                {
                    // Güvenlik için: Kullanıcı yoksa da başarılı mesajı döndür
                    return new ResetPasswordResponse
                    {
                        Success = true,
                        Message = "Eğer bu email adresine kayıtlı bir hesap varsa, şifre sıfırlama linki e-posta adresinize gönderilmiştir."
                    };
                }

                // Token oluştur (6 haneli Kod)
                string resetToken = new Random().Next(100000, 999999).ToString();

                // Token'ı veritabanına kaydet (1 saat geçerli)
                user.PasswordResetToken = resetToken;
                user.PasswordResetTokenExpiry = DateTime.UtcNow.AddHours(1);
                user.UpdatedAt = DateTime.UtcNow;

                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Şifre sıfırlama kodu oluşturuldu: {user.Email}");

                // Kod Sadece Log'da görünsün (Link oluşturmaya gerek yok artık)
                // -----------------------------------------------------------
                _logger.LogWarning("====== PASSWORD RESET CODE (OTP) ======");
                _logger.LogWarning($"User: {user.Email}");
                _logger.LogWarning($"CODE: {resetToken}");
                _logger.LogWarning("=======================================");
                // -----------------------------------------------------------

                // Email içeriğini güncelle (Link yerine Kod gönder)
                // Not: EmailService'deki HTML şablonu şimdilik link bekliyor ama çalışır, sadece link bozuk görünür. 
                // Önemli olan kodu iletmek.
                
                // Hızlı çözüm için resetUrl parametresine Kodu gönderiyoruz,
                // böylece mail şablonunda link yerine KOD yazacak.
                bool emailSent = await _emailService.SendPasswordResetEmailAsync(
                    user.Email, 
                    resetToken, 
                    user.DisplayName,
                    resetUrl: resetToken // Link yerine kodu basıyoruz
                );

                if (!emailSent)
                {
                    _logger.LogWarning($"Email gönderilemedi: {user.Email}. SMTP ayarlarını kontrol edin.");
                    
                    // GELİŞTİRME MODU (DEV MODE): 
                    // SMTP hatası olsa bile, geliştiricinin devam edebilmesi için başarılı dönüyoruz.
                    // Şifre sıfırlama kodu konsol/terminal çıktısında (warn loglarında) yazar.
                    return new ResetPasswordResponse
                    {
                        Success = true,
                        Message = "Test Modu: Email gönderilemedi (Ayarlar hatalı) ancak kod konsola yazıldı. Lütfen terminali kontrol edin."
                    };
                }

                return new ResetPasswordResponse
                {
                    Success = true,
                    Message = "Doğrulama kodu e-postanıza gönderildi. Lütfen spam kutunuzu da kontrol edin."
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Şifre sıfırlama hatası: {ex.Message}");
                return new ResetPasswordResponse
                {
                    Success = false,
                    Message = "Şifre sıfırlama işlemi sırasında hata oluştu."
                };
            }
        }

        /// <summary>
        /// Token ile şifre sıfırlama onayı ve yeni şifre belirleme
        /// </summary>
        public async Task<ConfirmResetPasswordResponse> ConfirmResetPasswordAsync(string token, string newPassword)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(newPassword))
                {
                    return new ConfirmResetPasswordResponse
                    {
                        Success = false,
                        Message = "Token ve yeni şifre gereklidir."
                    };
                }

                if (newPassword.Length < 6)
                {
                    return new ConfirmResetPasswordResponse
                    {
                        Success = false,
                        Message = "Şifre en az 6 karakter olmalıdır."
                    };
                }

                // Token ile kullanıcıyı bul
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.PasswordResetToken == token 
                        && u.PasswordResetTokenExpiry != null 
                        && u.PasswordResetTokenExpiry > DateTime.UtcNow);

                if (user == null)
                {
                    return new ConfirmResetPasswordResponse
                    {
                        Success = false,
                        Message = "Geçersiz veya süresi dolmuş token. Lütfen yeni bir şifre sıfırlama talebi oluşturun."
                    };
                }

                // Yeni şifreyi hash'le ve kaydet
                // 🔴 HATA DÜZELTME: Diğer kütüphane ile oluşturulduğu için salt versiyonu sorun yaratıyor olabilir.
                // En güvenli yöntem: Şifre sıfırlama işlemlerinde salt'ı yenilemektir.
                string passwordHash = BCrypt.Net.BCrypt.HashPassword(newPassword.Trim(), workFactor: 12);
                
                user.PasswordHash = passwordHash;
                user.Provider = "local";
                user.PasswordResetToken = null; // Token'ı temizle
                user.PasswordResetTokenExpiry = null;
                user.UpdatedAt = DateTime.UtcNow;

                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Şifre başarıyla sıfırlandı: {user.Email}");
                // DEBUG LOG:
                _logger.LogWarning($"NEW PASSWORD SET: {newPassword.Trim()} -> {passwordHash}");

                return new ConfirmResetPasswordResponse
                {
                    Success = true,
                    Message = "Şifreniz başarıyla güncellendi. Yeni şifrenizle giriş yapabilirsiniz."
                };
            }
            catch (Exception ex)
            {
                _logger.LogError($"Şifre sıfırlama onayı hatası: {ex.Message}");
                return new ConfirmResetPasswordResponse
                {
                    Success = false,
                    Message = "Şifre güncelleme işlemi sırasında hata oluştu."
                };
            }
        }

        public async Task<bool> UpdateUserAgreementsAsync(int userId, bool termsAccepted, bool privacyAccepted)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                user.TermsAccepted = termsAccepted;
                user.PrivacyAccepted = privacyAccepted;
                user.UpdatedAt = DateTime.UtcNow;

                _context.Users.Update(user);
                await _context.SaveChangesAsync();
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Agreement update failed: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Rastgele şifre oluştur
        /// </summary>
        private string GenerateRandomPassword(int length)
        {
            const string validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%";
            var random = new Random();
            return new string(Enumerable.Range(0, length)
                .Select(_ => validChars[random.Next(validChars.Length)])
                .ToArray());
        }
    }
}
