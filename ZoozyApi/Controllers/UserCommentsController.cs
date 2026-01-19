using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserCommentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public UserCommentsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/UserComments?cardId=moment_xxx&userName=xxx
    // TÜM KULLANICILARIN yorumlarını döndürür - userId filtresi YOK
    // User bilgilerini include ederek PhotoUrl'i de döndürür
    // Eğer cardId bulunamazsa, userName ile filtreleme yapılabilir (geçici çözüm)
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetUserComments([FromQuery] string? cardId, [FromQuery] string? userName)
    {
        var query = _context.UserComments
            .Include(c => c.User)
            .AsQueryable();

        if (!string.IsNullOrEmpty(cardId))
        {
            query = query.Where(c => c.CardId == cardId);
            
            // Eğer cardId ile yorum bulunamazsa ve userName varsa, userName ile filtrele
            var count = await query.CountAsync();
            if (count == 0 && !string.IsNullOrEmpty(userName) && cardId.StartsWith("moment_"))
            {
                System.Diagnostics.Debug.WriteLine($"⚠️ cardId ile yorum bulunamadı: {cardId}, userName ile filtreleme deneniyor: {userName}");
                query = _context.UserComments
                    .Include(c => c.User)
                    .Where(c => c.CardId.StartsWith($"moment_{userName}_"));
            }
        }

        // TÜM yorumları getir - userId filtresi YOK
        // User bilgilerini de dahil et (PhotoUrl için)
        var comments = await query
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new
            {
                c.Id,
                c.UserId,
                c.CardId,
                c.Message,
                c.Rating,
                c.AuthorName,
                // User tablosundan PhotoUrl'i al, yoksa AuthorAvatar'i kullan
                AuthorAvatar = c.User != null && !string.IsNullOrEmpty(c.User.PhotoUrl) 
                    ? c.User.PhotoUrl 
                    : c.AuthorAvatar,
                c.CreatedAt
            })
            .ToListAsync();

        // Debug: Kaç yorum bulundu?
        System.Diagnostics.Debug.WriteLine($"GetUserComments - cardId: {cardId}, Bulunan yorum sayısı: {comments.Count}");

        return Ok(comments);
    }

    // GET: api/UserComments/5
    [HttpGet("{id}")]
    public async Task<ActionResult<UserComment>> GetUserComment(int id)
    {
        var comment = await _context.UserComments.FindAsync(id);

        if (comment == null)
        {
            return NotFound();
        }

        return Ok(comment);
    }

    // POST: api/UserComments
    [HttpPost]
    public async Task<ActionResult<UserComment>> CreateUserComment([FromBody] UserComment comment)
    {
        try
        {
            // Debug: Gelen veriyi logla
            System.Diagnostics.Debug.WriteLine($"CreateUserComment - UserId: {comment.UserId}, CardId: {comment.CardId}, Message: {comment.Message}");

            // UserId validation ve User bilgilerini çek
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == comment.UserId);
            if (user == null)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Kullanıcı bulunamadı: UserId={comment.UserId}");
                return BadRequest(new { message = $"Geçersiz kullanıcı ID: {comment.UserId}" });
            }

            // User tablosundan PhotoUrl'i al ve AuthorAvatar olarak kaydet
            // Eğer AuthorAvatar gönderilmişse onu kullan, yoksa User'dan PhotoUrl'i al
            if (string.IsNullOrEmpty(comment.AuthorAvatar) && !string.IsNullOrEmpty(user.PhotoUrl))
            {
                comment.AuthorAvatar = user.PhotoUrl;
            }

            // AuthorName yoksa User'dan DisplayName'i al
            if (string.IsNullOrEmpty(comment.AuthorName))
            {
                comment.AuthorName = user.DisplayName;
            }

            comment.CreatedAt = DateTime.UtcNow;

            _context.UserComments.Add(comment);
            await _context.SaveChangesAsync();

            System.Diagnostics.Debug.WriteLine($"✅ Yorum başarıyla eklendi: Id={comment.Id}");

            return CreatedAtAction(nameof(GetUserComment), new { id = comment.Id }, comment);
        }
        catch (Exception ex)
        {
            // Inner exception'ı da logla (Entity Framework hataları için önemli)
            var errorMessage = ex.Message;
            if (ex.InnerException != null)
            {
                errorMessage += $" | Inner: {ex.InnerException.Message}";
                System.Diagnostics.Debug.WriteLine($"❌ Inner exception: {ex.InnerException.Message}");
                System.Diagnostics.Debug.WriteLine($"❌ Inner stack trace: {ex.InnerException.StackTrace}");
            }
            
            System.Diagnostics.Debug.WriteLine($"❌ Yorum ekleme hatası: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"❌ Stack trace: {ex.StackTrace}");
            
            return BadRequest(new { message = $"Yorum eklenirken hata oluştu: {errorMessage}" });
        }
    }

    // DELETE: api/UserComments/5?userId=1
    // Sadece kendi yorumunu silebilir - userId kontrolü yapılır
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUserComment(int id, [FromQuery] int userId)
    {
        var comment = await _context.UserComments.FindAsync(id);
        if (comment == null)
        {
            return NotFound(new { message = "Yorum bulunamadı." });
        }

        // Sadece kendi yorumunu silebilir kontrolü
        if (comment.UserId != userId)
        {
            System.Diagnostics.Debug.WriteLine($"❌ Yorum silme izni yok: Yorum UserId={comment.UserId}, İstek UserId={userId}");
            return StatusCode(403, new { message = "Sadece kendi yorumunuzu silebilirsiniz." });
        }

        System.Diagnostics.Debug.WriteLine($"✅ Yorum siliniyor: Id={id}, UserId={userId}");
        _context.UserComments.Remove(comment);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE: api/UserComments/by-card?cardId=moment_xxx
    [HttpDelete("by-card")]
    public async Task<IActionResult> DeleteCommentsByCard([FromQuery] string cardId)
    {
        var comments = await _context.UserComments
            .Where(c => c.CardId == cardId)
            .ToListAsync();

        if (!comments.Any())
        {
            return NotFound();
        }

        _context.UserComments.RemoveRange(comments);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/UserComments/all - DEBUG: Tüm yorumları listele (cardId'leri görmek için)
    [HttpGet("all")]
    public async Task<ActionResult<IEnumerable<object>>> GetAllComments()
    {
        var comments = await _context.UserComments
            .Select(c => new
            {
                c.Id,
                c.CardId,
                c.UserId,
                c.AuthorName,
                c.Message,
                c.CreatedAt
            })
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return Ok(comments);
    }
}

