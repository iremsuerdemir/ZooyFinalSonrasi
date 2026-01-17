using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcı bildirimleri
/// </summary>
public class Notification
{
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; } // Bildirimi alan kullanıcı
    
    [Required]
    [MaxLength(50)]
    public string Type { get; set; } = string.Empty; // "job" veya "message"
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    public int? RelatedUserId { get; set; } // İşlemi yapan kullanıcı (job oluşturan veya mesaj gönderen)
    
    public int? RelatedJobId { get; set; } // İlgili job (opsiyonel)
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public bool IsRead { get; set; } = false;
    
    // Navigation
    public User? User { get; set; }
    public User? RelatedUser { get; set; }
    public UserRequest? RelatedJob { get; set; }
}

