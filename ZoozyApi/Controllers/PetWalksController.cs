using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using ZoozyApi.Data;
using ZoozyApi.Dtos;
using ZoozyApi.Models;

namespace ZoozyApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PetWalksController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PetWalksController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/PetWalks/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<PetWalkDto>>> GetWalksByUser(int userId)
        {
            var walks = await _context.PetWalks
                .Where(w => w.UserId == userId)
                .OrderByDescending(w => w.Date)
                .ToListAsync();

            var result = walks.Select(w => new PetWalkDto
            {
                Id = w.Id,
                UserId = w.UserId,
                DurationSeconds = w.DurationSeconds,
                DistanceKm = w.DistanceKm,
                Date = w.Date,
                Path = string.IsNullOrEmpty(w.PathJson) 
                    ? new List<PathPointDto>() 
                    : JsonSerializer.Deserialize<List<PathPointDto>>(w.PathJson) ?? new(),
                Pets = string.IsNullOrEmpty(w.PetsJson)
                    ? new List<PetWalkItemDto>()
                    : JsonSerializer.Deserialize<List<PetWalkItemDto>>(w.PetsJson) ?? new()
            });

            return Ok(result);
        }

        // POST: api/PetWalks
        [HttpPost]
        public async Task<ActionResult<PetWalkDto>> CreateWalk(CreatePetWalkDto dto)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == dto.UserId);
            if (!userExists)
            {
                return BadRequest("User not found.");
            }

            var walk = new PetWalk
            {
                UserId = dto.UserId,
                DurationSeconds = dto.DurationSeconds,
                DistanceKm = dto.DistanceKm,
                Date = dto.Date,
                PathJson = JsonSerializer.Serialize(dto.Path),
                PetsJson = JsonSerializer.Serialize(dto.Pets)
            };

            _context.PetWalks.Add(walk);
            await _context.SaveChangesAsync();

            var savedDto = new PetWalkDto
            {
                Id = walk.Id,
                UserId = walk.UserId,
                DurationSeconds = walk.DurationSeconds,
                DistanceKm = walk.DistanceKm,
                Date = walk.Date,
                Path = dto.Path,
                Pets = dto.Pets
            };

            return CreatedAtAction(nameof(GetWalksByUser), new { userId = walk.UserId }, savedDto);
        }
    }
}
