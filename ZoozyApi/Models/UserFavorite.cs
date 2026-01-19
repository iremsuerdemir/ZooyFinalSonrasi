using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcının favori ilanları, bakıcıları veya moment'ları.
/// </summary>
public class UserFavorite
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public int UserId { get; set; }
    
    /// <summary>
    /// Favorinin başlığı (Örn: Bakıcı Adı, İlan Başlığı)
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    /// <summary>
    /// Alt başlık (Örn: Adres, Konum, Kısa Açıklama)
    /// </summary>
    [MaxLength(500)]
    public string? Subtitle { get; set; }
    
    /// <summary>
    /// Ana görsel URL (Hizmet görseli, İlan görseli)
    /// </summary>
    [MaxLength(1000)]
    public string? ImageUrl { get; set; }
    
    /// <summary>
    /// Profil resmi URL (Bakıcı profil fotosu)
    /// </summary>
    [MaxLength(1000)]
    public string? ProfileImageUrl { get; set; }
    
    /// <summary>
    /// Favori tipi: "caregiver", "explore", "moments" vb.
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Tip { get; set; } = "caregiver";
    
    /// <summary>
    /// Eğer başka bir kullanıcıyı takip ediyorsa, hedef kullanıcı ID'si
    /// </summary>
    public int? TargetUserId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // User tablosu ile ilişki
    [ForeignKey("UserId")]
    public User? User { get; set; }
}

