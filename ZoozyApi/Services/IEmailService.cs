namespace ZoozyApi.Services
{
    public interface IEmailService
    {
        Task<bool> SendPasswordResetEmailAsync(string toEmail, string resetToken, string displayName, string resetUrl);
        Task<bool> SendPasswordResetEmailAsync(string toEmail, string newPassword, string displayName); // Eski metod (geriye uyumluluk)
    }
}

