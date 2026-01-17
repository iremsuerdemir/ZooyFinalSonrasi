using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcı yorumları (Moments, Caregiver Profiles)
/// </summary>
public class UserComment
{
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string CardId { get; set; } = string.Empty; // "moment_xxx" or "caregiver_xxx"
    
    [Required]
    [MaxLength(2000)]
    public string Message { get; set; } = string.Empty;
    
    [Range(1, 5)]
    public int Rating { get; set; } = 5;
    
    [Required]
    [MaxLength(200)]
    public string AuthorName { get; set; } = string.Empty;
    
    // AuthorAvatar base64 string olabilir, bu yüzden MaxLength kaldırıldı (NVARCHAR(MAX) kullanılacak)
    public string? AuthorAvatar { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public User? User { get; set; }
}

