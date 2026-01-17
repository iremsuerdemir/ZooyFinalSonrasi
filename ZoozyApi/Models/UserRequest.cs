using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcının oluşturduğu hizmet talepleri (Requests Screen)
/// </summary>
public class UserRequest
{
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string PetName { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string ServiceName { get; set; } = string.Empty;
    
    // Base64 encoded image - NVARCHAR(MAX) için MaxLength kaldırıldı
    public string? UserPhoto { get; set; } // Base64 encoded image
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    public int DayDiff { get; set; }
    
    [MaxLength(1000)]
    public string? Note { get; set; }
    
    [MaxLength(500)]
    public string? Location { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public User? User { get; set; }
}

