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

    // DELETE: api/Messages/clear?jobId=1&userId=5&deleteConversation=true
    [HttpDelete("clear")]
    public async Task<IActionResult> ClearChat(
        [FromQuery] int jobId,
        [FromQuery] int userId,
        [FromQuery] bool deleteConversation = false)
    {
        var messages = await _context.Messages
            .Where(m =>
                m.JobId == jobId &&
                (m.SenderId == userId || m.ReceiverId == userId))
            .ToListAsync();

        if (!messages.Any())
        {
            if (deleteConversation)
            {
                 // Zaten mesaj yok, bir şey yapmaya gerek yok, ancak placeholder varsa onu da temizlemek isteyebiliriz?
                 // Eğer deleteConversation=true ise ve veritabanında sadece placeholder varsa veya hiç mesaj yoksa,
                 // zaten sonuç boş liste olacak.
                 return Ok(new { message = "Silinecek mesaj yok." });
            }
            // Eğer mesaj yoksa ama clear (deleteConversation=false) isteniyorsa, 
            // belki placeholder eklemeliyiz? 
            // Mevcut mantık: !messages.Any() -> return Ok.
            // Placeholder zaten bir mesaj sayıldığı için, eğer placeholder varsa messages.Any() true olur.
            return Ok(new { message = "Silinecek mesaj yok." });
        }

        // Placeholdermessage için diğer kullanıcıyı bul
        var lastMessage = messages.OrderByDescending(m => m.CreatedAt).First();
        int otherUserId = (lastMessage.SenderId == userId) ? lastMessage.ReceiverId : lastMessage.SenderId;

        _context.Messages.RemoveRange(messages);
        
        if (!deleteConversation)
        {
            // Sohbeti "boş" olarak listelerde tutmak için boş bir mesaj ekle
            var placeholderMessage = new Message
            {
                JobId = jobId,
                SenderId = userId,
                ReceiverId = otherUserId,
                MessageText = "", // Boş metin => Client tarafında filtrelenecek veya boş görünecek
                CreatedAt = DateTime.UtcNow
            };
            _context.Messages.Add(placeholderMessage);
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = deleteConversation ? "Sohbet tamamen silindi." : "Sohbet temizlendi." });
    }

    [HttpPost("start-conversation")]
    public async Task<IActionResult> StartConversation([FromBody] StartConversationDto dto)
    {
        if (dto.SenderId <= 0 || dto.ReceiverId <= 0)
        {
             return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        // 1. Check existing conversation via Messages
        var existingMessage = await _context.Messages
            .Where(m => (m.SenderId == dto.SenderId && m.ReceiverId == dto.ReceiverId) || 
                        (m.SenderId == dto.ReceiverId && m.ReceiverId == dto.SenderId))
            .OrderByDescending(m => m.CreatedAt)
            .FirstOrDefaultAsync();

        if (existingMessage != null)
        {
            return Ok(new { jobId = existingMessage.JobId });
        }

        // 2. Sender kontrolü
        var sender = await _context.Users.FindAsync(dto.SenderId);
        if (sender == null) return BadRequest(new { message = "Gönderen kullanıcı bulunamadı." });

        var newJob = new UserRequest
        {
            UserId = dto.SenderId,
            PetName = "Sohbet",
            ServiceName = "Mesajlaşma",
            StartDate = DateTime.UtcNow,
            EndDate = DateTime.UtcNow.AddYears(1),
            DayDiff = 1,
            Note = "Profil üzerinden başlatılan sohbet",
            Location = "Online",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            UserPhoto = "" 
        };

        _context.UserRequests.Add(newJob);
        await _context.SaveChangesAsync();
        
        return Ok(new { jobId = newJob.Id });
    }
}

public class StartConversationDto
{
    public int SenderId { get; set; }
    public int ReceiverId { get; set; }
}

