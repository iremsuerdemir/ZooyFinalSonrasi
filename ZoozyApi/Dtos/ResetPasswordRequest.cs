namespace ZoozyApi.Dtos
{
    public class ResetPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    public class ResetPasswordResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? NewPassword { get; set; } // Artık kullanılmıyor, geriye uyumluluk için
    }

    public class ConfirmResetPasswordRequest
    {
        public string Token { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class ConfirmResetPasswordResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
