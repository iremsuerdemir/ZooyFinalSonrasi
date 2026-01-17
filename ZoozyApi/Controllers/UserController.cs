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
                // Yeni kullanıcı oluştur
                user = new User
                {
                    FirebaseUid = dto.FirebaseUid,
                    Email = dto.Email,
                    DisplayName = dto.DisplayName,
                    PhotoUrl = normalizedPhotoUrl,
                    Provider = dto.Provider,
                    CreatedAt = DateTime.Now
                };

                _db.Users.Add(user);
            }
            else
            {
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

            // PhotoUrl null değilse VE boş string değilse VE sadece boşluk değilse güncelle
            // Ayrıca "data:image" ile başlamalı (base64 format kontrolü)
            if (dto.PhotoUrl != null)
            {
                var trimmedPhotoUrl = dto.PhotoUrl.Trim();
                
                // Geçerli base64 string kontrolü
                if (!string.IsNullOrWhiteSpace(trimmedPhotoUrl) && 
                    trimmedPhotoUrl.Length > 20 && // Minimum uzunluk kontrolü
                    trimmedPhotoUrl.StartsWith("data:image"))
                {
                    user.PhotoUrl = trimmedPhotoUrl;
                    System.Diagnostics.Debug.WriteLine($"✅ PhotoUrl güncellendi: Uzunluk={user.PhotoUrl.Length}, İlk 50 karakter: {user.PhotoUrl.Substring(0, Math.Min(50, user.PhotoUrl.Length))}");
                }
                else
                {
                    // Geçersiz PhotoUrl gönderildi - log'la ve GÜNCELLEME
                    var preview = trimmedPhotoUrl.Length > 50 ? trimmedPhotoUrl.Substring(0, 50) : trimmedPhotoUrl;
                    System.Diagnostics.Debug.WriteLine($"⚠️ Geçersiz PhotoUrl gönderildi (boş veya geçersiz format): Uzunluk={trimmedPhotoUrl.Length}, İçerik='{preview}'");
                    // Geçersizse NULL yap (boş string yerine)
                    user.PhotoUrl = null;
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
            var user = await _db.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            _db.Users.Remove(user);
            await _db.SaveChangesAsync();

            return Ok(new { success = true, message = "Kullanıcı başarıyla silindi" });
        }
    }
}
