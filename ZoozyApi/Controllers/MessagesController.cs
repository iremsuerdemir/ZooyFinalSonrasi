using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MessagesController : ControllerBase
{
    private readonly AppDbContext _context;

    public MessagesController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/Messages?jobId=1&userId=1
    // Belirli bir job için iki kullanıcı arasındaki mesajları getir
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetMessages(
        [FromQuery] int jobId,
        [FromQuery] int userId)
    {
        // Login olan kullanıcı sadece kendisine ait mesajları görmeli
        // (senderId veya receiverId = userId olan mesajlar)
        var messages = await _context.Messages
            .Where(m => m.JobId == jobId && (m.SenderId == userId || m.ReceiverId == userId))
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new
            {
                Id = m.Id,
                SenderId = m.SenderId,
                ReceiverId = m.ReceiverId,
                JobId = m.JobId,
                MessageText = m.MessageText,
                CreatedAt = m.CreatedAt,
                SenderUsername = m.Sender != null ? m.Sender.DisplayName : "",
                ReceiverUsername = m.Receiver != null ? m.Receiver.DisplayName : "",
                SenderPhotoUrl = m.Sender != null ? m.Sender.PhotoUrl : null,
                ReceiverPhotoUrl = m.Receiver != null ? m.Receiver.PhotoUrl : null
            })
            .ToListAsync();

        return Ok(messages);
    }

    // POST: api/Messages
    [HttpPost]
    public async Task<ActionResult<Message>> CreateMessage([FromBody] Message message)
    {
        // Validation
        var senderExists = await _context.Users.AnyAsync(u => u.Id == message.SenderId);
        var receiverExists = await _context.Users.AnyAsync(u => u.Id == message.ReceiverId);
        var jobExists = await _context.UserRequests.AnyAsync(j => j.Id == message.JobId);

        if (!senderExists || !receiverExists || !jobExists)
        {
            return BadRequest(new { message = "Geçersiz sender, receiver veya job ID." });
        }

        message.CreatedAt = DateTime.UtcNow;
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        // Kullanıcı kendi attığı mesajlar için bildirim görmemeli
        // Sadece receiver için bildirim oluştur
        if (message.SenderId != message.ReceiverId)
        {
            try
            {
                // Receiver kullanıcısını bul
                var receiver = await _context.Users.FindAsync(message.ReceiverId);
                var sender = await _context.Users.FindAsync(message.SenderId);

                if (receiver != null && sender != null)
                {
                    // Mesaj bildirimi oluştur
                    var notification = new Notification
                    {
                        UserId = message.ReceiverId,
                        Type = "message",
                        Title = $"{sender.DisplayName} kişisi size bir mesaj gönderdi",
                        RelatedUserId = message.SenderId,
                        RelatedJobId = message.JobId,
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false
                    };

                    _context.Notifications.Add(notification);
                    await _context.SaveChangesAsync();
                }
            }
            catch (Microsoft.Data.SqlClient.SqlException sqlEx) when (sqlEx.Number == 208) // Invalid object name
            {
                // Notifications tablosu yok - kritik değil, sadece log'la
                // Mesaj zaten kaydedildi, bu yüzden devam et
                System.Diagnostics.Debug.WriteLine("Notifications tablosu bulunamadı. Mesaj bildirimi oluşturulamadı.");
            }
            catch (Exception notificationEx)
            {
                // Bildirim oluşturma hatası kritik değil, sadece log'la
                // Mesaj zaten kaydedildi, bu yüzden devam et
                System.Diagnostics.Debug.WriteLine($"Mesaj bildirimi oluşturma hatası (kritik değil): {notificationEx.Message}");
            }
        }

        return CreatedAtAction(nameof(GetMessages), new { jobId = message.JobId, userId = message.SenderId }, message);
    }

    // GET: api/Messages/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<Message>> GetMessage(int id)
    {
        var message = await _context.Messages
            .Include(m => m.Sender)
            .Include(m => m.Receiver)
            .FirstOrDefaultAsync(m => m.Id == id);

        if (message == null)
        {
            return NotFound();
        }

        return Ok(message);
    }
}

