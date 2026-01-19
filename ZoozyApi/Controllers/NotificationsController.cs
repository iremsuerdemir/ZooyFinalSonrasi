using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public NotificationsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/Notifications?userId=1
    // Login olan kullanıcının bildirimlerini getir
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetNotifications([FromQuery] int userId)
    {
        // userId kontrolü - geçersiz userId ise hata döndür
        if (userId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        // Sadece bu kullanıcıya ait bildirimleri getir
        var notifications = await _context.Notifications
            .Where(n => n.UserId == userId)
            .Include(n => n.RelatedUser)
            .Include(n => n.RelatedJob)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new
            {
                Id = n.Id,
                UserId = n.UserId,
                Type = n.Type,
                Title = n.Title,
                RelatedUserId = n.RelatedUserId,
                RelatedJobId = n.RelatedJobId,
                CreatedAt = n.CreatedAt,
                IsRead = n.IsRead,
                RelatedUsername = n.RelatedUser != null ? n.RelatedUser.DisplayName : null
            })
            .ToListAsync();

        return Ok(notifications);
    }

    // PUT: api/Notifications/{id}/read
    // Bildirimi okundu olarak işaretle
    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null)
        {
            return NotFound();
        }

        notification.IsRead = true;
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE: api/Notifications/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(int id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null)
        {
            return NotFound();
        }

        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

