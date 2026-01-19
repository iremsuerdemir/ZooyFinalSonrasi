using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;
using ZoozyApi.Models.Dto;

namespace ZoozyApi.Controllers
{
    [ApiController]
    [Route("api/users")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _db;

        public UsersController(AppDbContext db)
        {
            _db = db;
        }

        // -------------------------------------------------------------
        // ✅ Kullanıcı bilgisi getir
        // GET: api/users/{firebaseUid}
        // -------------------------------------------------------------
        [HttpGet("{firebaseUid}")]
        public async Task<IActionResult> GetUser(string firebaseUid)
        {
            if (string.IsNullOrEmpty(firebaseUid))
                return BadRequest("firebaseUid boş olamaz");

            var user = await _db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUid);

            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı" });

            return Ok(user);
        }

        // -------------------------------------------------------------
        // ✅ Kullanıcı var mı kontrolü
        // GET: api/users/exists/{firebaseUid}
        // -------------------------------------------------------------
        [HttpGet("exists/{firebaseUid}")]
        public async Task<IActionResult> UserExists(string firebaseUid)
        {
            if (string.IsNullOrEmpty(firebaseUid))
                return BadRequest("firebaseUid boş olamaz");

            var exists = await _db.Users.AnyAsync(u => u.FirebaseUid == firebaseUid);
            return Ok(new { exists });
        }

        // -------------------------------------------------------------
        // 🔄 Kullanıcı senkronizasyonu (login sonrası)
        // POST: api/users/sync
        // -------------------------------------------------------------
        [HttpPost("sync")]
        public async Task<IActionResult> SyncUser([FromBody] SyncUserDto dto)
        {
            if (dto == null)
                return BadRequest("Dto gelmedi");

            if (string.IsNullOrEmpty(dto.FirebaseUid))
                return BadRequest("Uid zorunludur");

            var user = await _db.Users.FirstOrDefaultAsync(x => x.FirebaseUid == dto.FirebaseUid);

            // PhotoUrl'ü normalize et: null veya sadece boşluk ise NULL kaydet
            string? normalizedPhotoUrl = null;
            if (!string.IsNullOrWhiteSpace(dto.PhotoUrl))
            {
                normalizedPhotoUrl = dto.PhotoUrl!.Trim();
            }

            if (user == null)
            {
                // Slug oluştur
                string baseSlug = GenerateSlug(dto.DisplayName ?? "user");
                string slug = baseSlug;
                int count = 1;
                while (await _db.Users.AnyAsync(u => u.Slug == slug))
                {
                    slug = $"{baseSlug}_{count++}";
                }

                // Yeni kullanıcı oluştur
                user = new User
                {
                    FirebaseUid = dto.FirebaseUid,
                    Email = dto.Email,
                    DisplayName = dto.DisplayName,
                    Slug = slug,
                    PhotoUrl = normalizedPhotoUrl,
                    Provider = dto.Provider,
                    CreatedAt = DateTime.Now
                };

                _db.Users.Add(user);
            }
            else
            {
                // Slug yoksa oluştur (Eski kullanıcılar için)
                if (string.IsNullOrEmpty(user.Slug))
                {
                    string baseSlug = GenerateSlug(dto.DisplayName ?? "user");
                    string slug = baseSlug;
                    int count = 1;
                    while (await _db.Users.AnyAsync(u => u.Slug == slug))
                    {
                        slug = $"{baseSlug}_{count++}";
                    }
                    user.Slug = slug;
                }

                // Var olan kullanıcı güncelle
                user.Email = dto.Email;
                user.DisplayName = dto.DisplayName;
                user.PhotoUrl = normalizedPhotoUrl;
                user.Provider = dto.Provider;
                user.UpdatedAt = DateTime.Now;

                _db.Users.Update(user);
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "User synced",
                id = user.Id
            });
        }

        // -------------------------------------------------------------
        // 🆕 İlk kayıt (register)
        // POST: api/users/register
        // -------------------------------------------------------------
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] SyncUserDto dto)
        {
            if (dto == null)
                return BadRequest("Dto gelmedi");

            if (string.IsNullOrEmpty(dto.FirebaseUid))
                return BadRequest("Uid zorunludur");

            var existingUser = await _db.Users.FirstOrDefaultAsync(x => x.FirebaseUid == dto.FirebaseUid);

            if (existingUser != null)
            {
                return Conflict(new { message = "User already exists" }); // 409
            }

            // PhotoUrl'ü normalize et: null veya sadece boşluk ise NULL kaydet
            string? normalizedPhotoUrl = null;
            if (!string.IsNullOrWhiteSpace(dto.PhotoUrl))
            {
                normalizedPhotoUrl = dto.PhotoUrl!.Trim();
            }

            var newUser = new User
            {
                FirebaseUid = dto.FirebaseUid,
                Email = dto.Email,
                DisplayName = dto.DisplayName,
                PhotoUrl = normalizedPhotoUrl,
                Provider = dto.Provider,
                CreatedAt = DateTime.Now
            };

            _db.Users.Add(newUser);
            await _db.SaveChangesAsync();

            return StatusCode(201, new
            {
                message = "User created",
                id = newUser.Id
            });
        }

        // -------------------------------------------------------------
        // 🔄 Kullanıcı profil güncelleme (PhotoUrl dahil)
        // PUT: api/users/{id}
        // -------------------------------------------------------------
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto)
        {
            if (dto == null)
                return BadRequest("Dto gelmedi");

            var user = await _db.Users.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı" });

            // Güncelleme
            if (!string.IsNullOrEmpty(dto.DisplayName))
                user.DisplayName = dto.DisplayName;
            
            // Bio güncellemesi (null gelebilir, güncellemek istemiyorsa null gelir, silmek istiyorsa boş string gelebilir)
            if (dto.Bio != null)
                user.Bio = dto.Bio;

            // PhotoUrl null değilse VE boş string değilse VE sadece boşluk değilse güncelle
            // Hem Base64 ("data:image") hem de Web URL ("http") formatlarını kabul et
            if (dto.PhotoUrl != null)
            {
                var trimmedPhotoUrl = dto.PhotoUrl.Trim();
                
                // Geçerli URL veya Base64 string kontrolü
                if (!string.IsNullOrWhiteSpace(trimmedPhotoUrl) && 
                    (trimmedPhotoUrl.StartsWith("data:image", StringComparison.OrdinalIgnoreCase) || 
                     trimmedPhotoUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase)))
                {
                    user.PhotoUrl = trimmedPhotoUrl;
                    System.Diagnostics.Debug.WriteLine($"✅ PhotoUrl güncellendi: Uzunluk={user.PhotoUrl.Length}, İlk 50 karakter: {user.PhotoUrl.Substring(0, Math.Min(50, user.PhotoUrl.Length))}");
                }
                else
                {
                    // Geçersiz PhotoUrl gönderildi - log'la ama GÜNCELLEME (Eski resim kalsın veya null yapma)
                    var preview = trimmedPhotoUrl.Length > 50 ? trimmedPhotoUrl.Substring(0, 50) : trimmedPhotoUrl;
                    System.Diagnostics.Debug.WriteLine($"⚠️ Geçersiz PhotoUrl formatı: Uzunluk={trimmedPhotoUrl.Length}, İçerik='{preview}'");
                    // user.PhotoUrl = null; // Eski hali: null yapıyordu. Yeni hali: dokunma.
                }
            }

            user.UpdatedAt = DateTime.UtcNow;

            _db.Users.Update(user);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "Kullanıcı güncellendi",
                id = user.Id,
                displayName = user.DisplayName,
                photoUrl = user.PhotoUrl
            });
        }

        // -------------------------------------------------------------
        // 🗑️ Kullanıcı Silme (Hesap Kapatma)
        // DELETE: api/users/{id}
        // -------------------------------------------------------------
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            using var transaction = await _db.Database.BeginTransactionAsync();
            try 
            {
                System.Diagnostics.Debug.WriteLine($"DELETE Request received for User ID: {id}");
                
                var user = await _db.Users.FindAsync(id);
                if (user == null)
                {
                    System.Diagnostics.Debug.WriteLine($"User not found for ID: {id}");
                    return NotFound(new { message = "Kullanıcı bulunamadı" });
                }

                // 1. İLGİLİ MESAJLARI SİL (Sender/Receiver Restrict olduğu için manuel silmeliyiz)
                var messages = await _db.Messages
                    .Where(m => m.SenderId == id || m.ReceiverId == id)
                    .ToListAsync();
                if (messages.Any())
                {
                    _db.Messages.RemoveRange(messages);
                    System.Diagnostics.Debug.WriteLine($"Deleted {messages.Count} related messages.");
                }

                // 2. İLGİLİ BİLDİRİMLERİ SİL (RelatedUser Restrict olduğu için)
                // Kendi bildirimleri (UserId) Cascade ile silinir, ama RelatedUser olduklarını silelim.
                var relatedNotifications = await _db.Notifications
                    .Where(n => n.RelatedUserId == id)
                    .ToListAsync();
                if (relatedNotifications.Any())
                {
                    _db.Notifications.RemoveRange(relatedNotifications);
                     System.Diagnostics.Debug.WriteLine($"Deleted {relatedNotifications.Count} related notifications.");
                }

                // 3. PET PROFILLERİNE BAĞLI SERVICE REQUESTLERİ SİL
                // PetProfile -> User (Cascade) ama ServiceRequest -> PetProfile (Restrict)
                // Bu yüzden önce petlerin joblarını silmeliyiz.
                var userPetIds = await _db.PetProfiles
                    .Where(p => p.UserId == id)
                    .Select(p => p.Id)
                    .ToListAsync();

                if (userPetIds.Any())
                {
                    var petRequests = await _db.ServiceRequests
                        .Where(r => userPetIds.Contains(r.PetProfileId))
                        .ToListAsync();
                    
                    if (petRequests.Any())
                    {
                        _db.ServiceRequests.RemoveRange(petRequests);
                        System.Diagnostics.Debug.WriteLine($"Deleted {petRequests.Count} service requests linked to user pets.");
                    }
                }

                // 4. KULLANICIYI SİL (Kalanlar Cascade ile silinecek: UserRequests, Favorites, Comments, Services, Own Notifications, Pets)
                _db.Users.Remove(user);
                await _db.SaveChangesAsync();
                
                await transaction.CommitAsync();
                
                System.Diagnostics.Debug.WriteLine($"User {id} deleted successfully.");

                return Ok(new { success = true, message = "Kullanıcı başarıyla silindi" });
            }
            catch (Exception ex)
            {
                 await transaction.RollbackAsync();
                 System.Diagnostics.Debug.WriteLine($"DELETE Error: {ex}");
                 // Inner exception detayını da loglayalım
                 var innerMsg = ex.InnerException?.Message ?? "";
                 return StatusCode(500, new { success = false, message = "Sunucu hatası: " + ex.Message + " " + innerMsg });
            }
        }

        // -------------------------------------------------------------
        // 📊 Kullanıcı İstatistikleri (Takipçi, Takip, Yorum)
        // GET: api/users/{id}/stats
        // -------------------------------------------------------------
        [HttpGet("{id}/stats")]
        public async Task<IActionResult> GetUserStats(int id)
        {
            var user = await _db.Users.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı" });

            return await _getStatsInternal(user);
        }

        // GET: api/users/slug/{slug}/stats
        [HttpGet("slug/{slug}/stats")]
        public async Task<IActionResult> GetUserStatsBySlug(string slug)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Slug == slug);
            if (user == null)
                return NotFound(new { message = "Kullanıcı bulunamadı" });

            return await _getStatsInternal(user);
        }

        private async Task<IActionResult> _getStatsInternal(User user)
        {
            // 1. Following (Takip Edilenler)
            // User favorites with Tip = 'caregiver', 'profile' or 'takip'
            var followingCount = await _db.UserFavorites
                .CountAsync(f => f.UserId == user.Id && (f.Tip == "caregiver" || f.Tip == "profile" || f.Tip == "takip"));

            // 2. Followers (Takipçiler) (Gelişmiş)
            // Eğer TargetUserId kullanılıyorsa ona bak, yoksa Title eşleşmesine (eski kayıtlar için)
            var followerCount = await _db.UserFavorites
                .Where(f => (f.Tip == "caregiver" || f.Tip == "profile" || f.Tip == "takip"))
                .Where(f => (f.TargetUserId == user.Id) || (f.TargetUserId == null && f.Title == user.DisplayName))
                .CountAsync();

            // 3. Comments/Reviews (Hakkındaki yorumlar)
             var reviewCount = await _db.UserComments
                .CountAsync(c => c.CardId == user.DisplayName || c.CardId == "moment_" + user.DisplayName);
            
            return Ok(new 
            {
                statsId = user.Id, // Hangi user için olduğunu dönelim
                followers = followerCount,
                following = followingCount,
                reviews = reviewCount
            });
        }


        private string GenerateSlug(string displayName)
        {
            if (string.IsNullOrWhiteSpace(displayName)) return "user";

            string slug = displayName.ToLowerInvariant();
            // Turkish characters mapping
            slug = slug.Replace("ı", "i").Replace("ğ", "g").Replace("ü", "u").Replace("ş", "s").Replace("ö", "o").Replace("ç", "c");
            // Remove invalid chars
            slug = System.Text.RegularExpressions.Regex.Replace(slug, @"[^a-z0-9\s-]", "");
            // Replace spaces with underscore
            slug = System.Text.RegularExpressions.Regex.Replace(slug, @"\s+", "_").Trim();

            return slug;
        }
    }
}
