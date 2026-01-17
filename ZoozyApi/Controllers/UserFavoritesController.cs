using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserFavoritesController : ControllerBase
{
    private readonly AppDbContext _context;

    public UserFavoritesController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/UserFavorites?userId=1&tip=explore
    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserFavorite>>> GetUserFavorites(
        [FromQuery] int? userId,
        [FromQuery] string? tip)
    {
        var query = _context.UserFavorites.AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(f => f.UserId == userId.Value);
        }

        if (!string.IsNullOrEmpty(tip))
        {
            query = query.Where(f => f.Tip == tip);
        }

        var favorites = await query
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return Ok(favorites);
    }

    // GET: api/UserFavorites/5
    [HttpGet("{id}")]
    public async Task<ActionResult<UserFavorite>> GetUserFavorite(int id)
    {
        var favorite = await _context.UserFavorites.FindAsync(id);

        if (favorite == null)
        {
            return NotFound();
        }

        return Ok(favorite);
    }

    // POST: api/UserFavorites
    [HttpPost]
    public async Task<ActionResult<UserFavorite>> CreateUserFavorite([FromBody] UserFavorite favorite)
    {
        // UserId validation
        var userExists = await _context.Users.AnyAsync(u => u.Id == favorite.UserId);
        if (!userExists)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        // Check if already exists (prevent duplicates)
        var exists = await _context.UserFavorites
            .AnyAsync(f => f.UserId == favorite.UserId &&
                          f.Title == favorite.Title &&
                          f.Tip == favorite.Tip &&
                          (string.IsNullOrEmpty(favorite.ImageUrl) || f.ImageUrl == favorite.ImageUrl));

        if (exists)
        {
            return Conflict(new { message = "Bu favori zaten eklenmiş." });
        }

        favorite.CreatedAt = DateTime.UtcNow;

        _context.UserFavorites.Add(favorite);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetUserFavorite), new { id = favorite.Id }, favorite);
    }

    // DELETE: api/UserFavorites/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUserFavorite(int id)
    {
        var favorite = await _context.UserFavorites.FindAsync(id);
        if (favorite == null)
        {
            return NotFound();
        }

        _context.UserFavorites.Remove(favorite);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE: api/UserFavorites/by-identifier?userId=1&title=xxx&tip=explore
    [HttpDelete("by-identifier")]
    public async Task<IActionResult> DeleteUserFavoriteByIdentifier(
        [FromQuery] int userId,
        [FromQuery] string title,
        [FromQuery] string tip,
        [FromQuery] string? imageUrl = null)
    {
        var query = _context.UserFavorites
            .Where(f => f.UserId == userId && f.Title == title && f.Tip == tip);

        if (!string.IsNullOrEmpty(imageUrl))
        {
            query = query.Where(f => f.ImageUrl == imageUrl);
        }

        var favorites = await query.ToListAsync();

        if (!favorites.Any())
        {
            return NotFound();
        }

        _context.UserFavorites.RemoveRange(favorites);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/UserFavorites/count?title=xxx&tip=moments&imageUrl=xxx
    [HttpGet("count")]
    public async Task<ActionResult<int>> GetFavoriteCount(
        [FromQuery] string title,
        [FromQuery] string tip,
        [FromQuery] string? imageUrl = null)
    {
        var query = _context.UserFavorites
            .Where(f => f.Title == title && f.Tip == tip);

        if (!string.IsNullOrEmpty(imageUrl))
        {
            query = query.Where(f => f.ImageUrl == imageUrl);
        }

        var count = await query.CountAsync();
        return Ok(count);
    }

    // GET: api/UserFavorites/users?title=xxx&tip=moments&imageUrl=xxx
    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<object>>> GetFavoriteUsers(
        [FromQuery] string title,
        [FromQuery] string tip,
        [FromQuery] string? imageUrl = null)
    {
        var query = _context.UserFavorites
            .Include(f => f.User)
            .Where(f => f.Title == title && f.Tip == tip);

        if (!string.IsNullOrEmpty(imageUrl))
        {
            query = query.Where(f => f.ImageUrl == imageUrl);
        }

        var favorites = await query
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new
            {
                userId = f.UserId,
                displayName = f.User != null ? f.User.DisplayName : "Bilinmeyen Kullanıcı",
                photoUrl = f.User != null ? f.User.PhotoUrl : null
            })
            .ToListAsync();

        return Ok(favorites);
    }
}

