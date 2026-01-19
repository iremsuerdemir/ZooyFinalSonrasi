using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Models;

/// <summary>
/// Kullanıcılar arası mesajlaşma
/// </summary>
public class Message
{
    public int Id { get; set; }
    
    [Required]
    public int SenderId { get; set; }
    
    [Required]
    public int ReceiverId { get; set; }
    
    [Required]
    public int JobId { get; set; } // UserRequest Id
    
    [Required]
    [MaxLength(2000)]
    public string MessageText { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public User? Sender { get; set; }
    public User? Receiver { get; set; }
    public UserRequest? Job { get; set; }
}

