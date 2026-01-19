using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserRequestsController : ControllerBase
{
    private readonly AppDbContext _context;

    public UserRequestsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/UserRequests?userId=1
    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserRequest>>> GetUserRequests([FromQuery] int? userId)
    {
        var query = _context.UserRequests.AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(r => r.UserId == userId.Value);
        }

        var requests = await query
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return Ok(requests);
    }

    // GET: api/UserRequests/all
    // Tüm kullanıcıların job'larını getir (global feed - filtreleme yok)
    [HttpGet("all")]
    public async Task<ActionResult<IEnumerable<object>>> GetAllJobs()
    {
        var requests = await _context.UserRequests
            .Join(
                _context.Users,
                request => request.UserId,
                user => user.Id,
                (request, user) => new
                {
                    Id = request.Id,
                    UserId = request.UserId,
                    PetName = request.PetName,
                    ServiceName = request.ServiceName,
                    UserPhoto = request.UserPhoto,
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    DayDiff = request.DayDiff,
                    Note = request.Note,
                    Location = request.Location,
                    CreatedAt = request.CreatedAt,
                    UpdatedAt = request.UpdatedAt,
                    // Job'u oluşturan kullanıcı bilgileri
                    CreatedByUserId = request.UserId,
                    CreatedByName = user.DisplayName,
                    UserDisplayName = user.DisplayName,
                    UserEmail = user.Email,
                    UserPhotoUrl = user.PhotoUrl
                }
            )
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return Ok(requests);
    }

    // GET: api/UserRequests/others?excludeUserId=1
    // Login olan kullanıcı hariç tüm kullanıcıların user request'lerini getir
    [HttpGet("others")]
    public async Task<ActionResult<IEnumerable<object>>> GetOtherUsersRequests([FromQuery] int excludeUserId)
    {
        // excludeUserId kontrolü
        if (excludeUserId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        // Sadece excludeUserId dışındaki kullanıcıların request'lerini getir
        var requests = await _context.UserRequests
            .Where(r => r.UserId != excludeUserId)
            .Join(
                _context.Users,
                request => request.UserId,
                user => user.Id,
                (request, user) => new
                {
                    Id = request.Id,
                    UserId = request.UserId,
                    PetName = request.PetName,
                    ServiceName = request.ServiceName,
                    UserPhoto = request.UserPhoto,
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    DayDiff = request.DayDiff,
                    Note = request.Note,
                    Location = request.Location,
                    CreatedAt = request.CreatedAt,
                    UpdatedAt = request.UpdatedAt,
                    // Kullanıcı bilgileri
                    UserDisplayName = user.DisplayName,
                    UserEmail = user.Email,
                    UserPhotoUrl = user.PhotoUrl
                }
            )
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return Ok(requests);
    }

    // GET: api/UserRequests/5
    [HttpGet("{id}")]
    public async Task<ActionResult<UserRequest>> GetUserRequest(int id)
    {
        var request = await _context.UserRequests.FindAsync(id);

        if (request == null)
        {
            return NotFound();
        }

        return Ok(request);
    }

    // POST: api/UserRequests
    [HttpPost]
    public async Task<ActionResult<UserRequest>> CreateUserRequest([FromBody] UserRequest request)
    {
        try
        {
            // UserId validation
            if (request.UserId <= 0)
            {
                return BadRequest(new { message = "Geçersiz kullanıcı ID." });
            }

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
            {
                return BadRequest(new { message = "Kullanıcı bulunamadı. Lütfen giriş yapın." });
            }

            // Required field validations
            if (string.IsNullOrWhiteSpace(request.PetName))
            {
                return BadRequest(new { message = "Evcil hayvan adı gereklidir." });
            }

            if (string.IsNullOrWhiteSpace(request.ServiceName))
            {
                return BadRequest(new { message = "Hizmet adı gereklidir." });
            }

            request.CreatedAt = DateTime.UtcNow;
            request.UpdatedAt = DateTime.UtcNow;

            _context.UserRequests.Add(request);
            await _context.SaveChangesAsync();

            // Job oluşturulduğunda bildirim oluştur
            // Notifications tablosu varsa bildirim gönder
            try
            {
                // Job'u oluşturan kullanıcıyı bul
                var jobCreator = await _context.Users.FindAsync(request.UserId);
                if (jobCreator != null)
                {
                    // Tüm diğer aktif kullanıcılara bildirim gönder
                    var otherUsers = await _context.Users
                        .Where(u => u.Id != request.UserId && u.IsActive)
                        .ToListAsync();

                    foreach (var user in otherUsers)
                    {
                        var notification = new Notification
                        {
                            UserId = user.Id,
                            Type = "job",
                            Title = $"{jobCreator.DisplayName} kişisi yeni bir iş yayınladı",
                            RelatedUserId = request.UserId,
                            RelatedJobId = request.Id,
                            CreatedAt = DateTime.UtcNow,
                            IsRead = false
                        };

                        _context.Notifications.Add(notification);
                    }

                    await _context.SaveChangesAsync();
                }
            }
            catch (Microsoft.Data.SqlClient.SqlException sqlEx) when (sqlEx.Number == 208) // Invalid object name
            {
                // Notifications tablosu yok - kritik değil, sadece log'la
                // UserRequest zaten kaydedildi, bu yüzden devam et
                System.Diagnostics.Debug.WriteLine("Notifications tablosu bulunamadı. Bildirimler oluşturulamadı.");
            }
            catch (Exception notificationEx)
            {
                // Bildirim oluşturma hatası kritik değil, sadece log'la
                // UserRequest zaten kaydedildi, bu yüzden devam et
                System.Diagnostics.Debug.WriteLine($"Bildirim oluşturma hatası (kritik değil): {notificationEx.Message}");
            }

            return CreatedAtAction(nameof(GetUserRequest), new { id = request.Id }, request);
        }
        catch (DbUpdateException dbEx)
        {
            // Veritabanı hatası - inner exception'ı göster
            var innerMessage = dbEx.InnerException?.Message ?? dbEx.Message;
            return StatusCode(500, new { message = $"Talep kaydedilirken bir hata oluştu: {innerMessage}" });
        }
        catch (Exception ex)
        {
            // Diğer hatalar - inner exception'ı göster
            var innerMessage = ex.InnerException?.Message ?? ex.Message;
            return StatusCode(500, new { message = $"Talep kaydedilirken bir hata oluştu: {innerMessage}" });
        }
    }

    // PUT: api/UserRequests/5
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUserRequest(int id, [FromBody] UserRequest updatedRequest)
    {
        if (id != updatedRequest.Id)
        {
            return BadRequest();
        }

        var existing = await _context.UserRequests.FindAsync(id);
        if (existing == null)
        {
            return NotFound();
        }

        existing.PetName = updatedRequest.PetName;
        existing.ServiceName = updatedRequest.ServiceName;
        existing.UserPhoto = updatedRequest.UserPhoto;
        existing.StartDate = updatedRequest.StartDate;
        existing.EndDate = updatedRequest.EndDate;
        existing.DayDiff = updatedRequest.DayDiff;
        existing.Note = updatedRequest.Note;
        existing.Location = updatedRequest.Location;
        existing.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.UserRequests.AnyAsync(r => r.Id == id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    // DELETE: api/UserRequests/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUserRequest(int id)
    {
        try
        {
            var request = await _context.UserRequests.FindAsync(id);
            if (request == null)
            {
                return NotFound();
            }

            // İlişkili bildirimleri önce sil (eğer Notifications tablosu varsa)
            try
            {
                var relatedNotifications = _context.Notifications
                    .Where(n => n.RelatedJobId == id);

                _context.Notifications.RemoveRange(relatedNotifications);
            }
            catch (Microsoft.Data.SqlClient.SqlException sqlEx) when (sqlEx.Number == 208) // Invalid object name
            {
                // Notifications tablosu yok - kritik değil, devam et
                System.Diagnostics.Debug.WriteLine("Notifications tablosu bulunamadı. Bildirimler silinemedi.");
            }
            catch (Exception notificationEx)
            {
                // Bildirim silme hatası kritik değil, devam et
                System.Diagnostics.Debug.WriteLine($"Bildirim silme hatası (kritik değil): {notificationEx.Message}");
            }

            _context.UserRequests.Remove(request);
            await _context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            var innerMessage = ex.InnerException?.Message ?? ex.Message;
            return StatusCode(500, new { message = $"Talep silinirken bir hata oluştu: {innerMessage}" });
        }
    }

}

