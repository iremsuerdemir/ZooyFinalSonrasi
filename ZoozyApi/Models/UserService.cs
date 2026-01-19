using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcının profil ekranındaki hizmet kartları (Profile Screen)
/// </summary>
public class UserService
{
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string ServiceName { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? ServiceIcon { get; set; }
    
    [MaxLength(50)]
    public string? Price { get; set; }
    
    [MaxLength(1000)]
    public string? Description { get; set; }
    
    [Required]
    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public User? User { get; set; }
}

