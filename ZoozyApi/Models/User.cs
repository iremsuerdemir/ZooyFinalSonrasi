namespace ZoozyApi.Models
{
    public class User
    {
        public int Id { get; set; }
        public string? FirebaseUid { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? PasswordHash { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? Slug { get; set; } // URL dostu kullanıcı adı
        public string? PhotoUrl { get; set; }
        public string? Bio { get; set; } // Yeni alan: Hakkımda yazısı
        public string Provider { get; set; } = "local";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public bool IsActive { get; set; } = true;
        
        // Şifre sıfırlama token'ı
        public string? PasswordResetToken { get; set; }
        public DateTime? PasswordResetTokenExpiry { get; set; }

        // Sözleşme Onayları
        public bool TermsAccepted { get; set; } = false;
        public bool PrivacyAccepted { get; set; } = false;

        // Navigation property - User'ın pet profilleri
        public ICollection<PetProfile> PetProfiles { get; set; } = new List<PetProfile>();
    }
}
