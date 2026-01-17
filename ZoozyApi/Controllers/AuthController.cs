using Microsoft.AspNetCore.Mvc;
using ZoozyApi.Dtos;
using ZoozyApi.Services;

namespace ZoozyApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        /// <summary>
        /// Email ve şifre ile kayıt ol
        /// POST /api/auth/register
        /// </summary>
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new AuthResponse 
                { 
                    Success = false, 
                    Message = "Geçersiz istek." 
                });
            }

            var result = await _authService.RegisterAsync(request);
            return result.Success ? Ok(result) : BadRequest(result);
        }

        /// <summary>
        /// Email ve şifre ile giriş yap
        /// POST /api/auth/login
        /// </summary>
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new AuthResponse 
                { 
                    Success = false, 
                    Message = "Geçersiz istek." 
                });
            }

            var result = await _authService.LoginAsync(request);
            return result.Success ? Ok(result) : Unauthorized(result);
        }

        /// <summary>
        /// Google Firebase UID ile login/register
        /// POST /api/auth/google-login
        /// </summary>
        [HttpPost("google-login")]
        public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new AuthResponse 
                { 
                    Success = false, 
                    Message = "Geçersiz istek." 
                });
            }

            var result = await _authService.GoogleLoginAsync(request);
            return result.Success ? Ok(result) : BadRequest(result);
        }

        /// <summary>
        /// Kullanıcı bilgilerini al (ID ile)
        /// GET /api/auth/user/{id}
        /// </summary>
        [HttpGet("user/{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            var user = await _authService.GetUserByIdAsync(id);
            if (user == null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı." });
            }

            return Ok(new { success = true, user });
        }

        /// <summary>
        /// Kullanıcı bilgilerini al (Email ile)
        /// GET /api/auth/user-by-email/{email}
        /// </summary>
        [HttpGet("user-by-email/{email}")]
        public async Task<IActionResult> GetUserByEmail(string email)
        {
            var user = await _authService.GetUserByEmailAsync(email);
            if (user == null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı." });
            }

            return Ok(new { success = true, user });
        }

        /// <summary>
        /// Şifre sıfırlama linki gönder
        /// POST /api/auth/reset-password
        /// </summary>
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Email))
            {
                return BadRequest(new { success = false, message = "Email gereklidir." });
            }

            var result = await _authService.ResetPasswordAsync(request.Email);
            return result.Success ? Ok(result) : BadRequest(result);
        }

        /// <summary>
        /// Yeni şifreyi onayla
        /// POST /api/auth/confirm-reset-password
        /// </summary>
        [HttpPost("confirm-reset-password")]
        public async Task<IActionResult> ConfirmResetPassword([FromBody] ConfirmResetPasswordRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new { success = false, message = "Geçersiz istek." });
            }

            var result = await _authService.ConfirmResetPasswordAsync(request.Token, request.NewPassword);
            return result.Success ? Ok(result) : BadRequest(result);
        }
        
        /// <summary>
        /// Kullanıcı sözleşme onaylarını güncelle
        /// POST /api/auth/update-agreements
        /// </summary>
        [HttpPost("update-agreements")]
        public async Task<IActionResult> UpdateAgreements([FromBody] UpdateAgreementsRequest request)
        {
            if (request == null || request.UserId <= 0)
            {
                return BadRequest(new { success = false, message = "Geçersiz istek." });
            }

            var result = await _authService.UpdateUserAgreementsAsync(request.UserId, request.TermsAccepted, request.PrivacyAccepted);
            
            if (result)
            {
                return Ok(new { success = true, message = "Sözleşme onayları güncellendi." });
            }
            return BadRequest(new { success = false, message = "Güncelleme başarısız." });
        }
    }
}
