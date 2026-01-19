using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;
using ZoozyApi.Dtos;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PetProfilesController : ControllerBase
{
    private readonly AppDbContext _context;

    public PetProfilesController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all pets for the current user
    /// GET: /api/petprofiles/my?userId=1
    /// </summary>
    [HttpGet("my")]
    public async Task<ActionResult<IEnumerable<PetProfile>>> GetMyPets([FromQuery] int userId, CancellationToken cancellationToken)
    {
        if (userId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        var pets = await _context.PetProfiles
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.UpdatedAt)
            .ToListAsync(cancellationToken);

        return Ok(pets);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<PetProfile>>> GetAllAsync(CancellationToken cancellationToken)
    {
        var pets = await _context.PetProfiles
            .AsNoTracking()
            .OrderByDescending(p => p.UpdatedAt)
            .ToListAsync(cancellationToken);

        return Ok(pets);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PetProfile>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var pet = await _context.PetProfiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (pet is null)
        {
            return NotFound();
        }

        return Ok(pet);
    }

    /// <summary>
    /// Create a new pet profile for the current user
    /// POST: /api/petprofiles?userId=1
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PetProfile>> CreateAsync([FromBody] CreatePetDto dto, [FromQuery] int userId, CancellationToken cancellationToken)
    {
        if (userId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        // User exists check
        var userExists = await _context.Users.AnyAsync(u => u.Id == userId, cancellationToken);
        if (!userExists)
        {
            return BadRequest(new { message = "Kullanıcı bulunamadı." });
        }

        var petProfile = new PetProfile
        {
            Id = Guid.NewGuid(),
            Name = dto.Name,
            Species = dto.Species,
            Breed = dto.Breed,
            Age = dto.Age,
            Weight = dto.Weight,
            VaccinationStatus = dto.VaccinationStatus,
            HealthNotes = dto.HealthNotes,
            OwnerName = dto.OwnerName,
            OwnerContact = dto.OwnerContact,
            UserId = userId,
            FirebaseId = Guid.NewGuid().ToString(), // Temporary FirebaseId
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.PetProfiles.Add(petProfile);
        await _context.SaveChangesAsync(cancellationToken);

        // return CreatedAtAction(nameof(GetByIdAsync), new { id = petProfile.Id }, petProfile);
        return StatusCode(201, petProfile);
    }

    /// <summary>
    /// Update a pet profile (only if it belongs to the user)
    /// PUT: /api/petprofiles/{id}?userId=1
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateAsync(Guid id, [FromBody] CreatePetDto dto, [FromQuery] int userId, CancellationToken cancellationToken)
    {
        if (userId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        var existing = await _context.PetProfiles.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (existing is null)
        {
            return NotFound(new { message = "Pet profili bulunamadı." });
        }

        // Check if pet belongs to user
        if (existing.UserId != userId)
        {
            return Forbid("Bu pet profili size ait değil.");
        }

        existing.Name = dto.Name;
        existing.Species = dto.Species;
        existing.Breed = dto.Breed;
        existing.Age = dto.Age;
        existing.Weight = dto.Weight;
        existing.VaccinationStatus = dto.VaccinationStatus;
        existing.HealthNotes = dto.HealthNotes;
        existing.OwnerName = dto.OwnerName;
        existing.OwnerContact = dto.OwnerContact;
        existing.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    /// <summary>
    /// Delete a pet profile (only if it belongs to the user)
    /// DELETE: /api/petprofiles/{id}?userId=1
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteAsync(Guid id, [FromQuery] int userId, CancellationToken cancellationToken)
    {
        if (userId <= 0)
        {
            return BadRequest(new { message = "Geçersiz kullanıcı ID." });
        }

        var existing = await _context.PetProfiles.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (existing is null)
        {
            return NotFound(new { message = "Pet profili bulunamadı." });
        }

        // Check if pet belongs to user
        if (existing.UserId != userId)
        {
            return Forbid("Bu pet profili size ait değil.");
        }

        _context.PetProfiles.Remove(existing);
        await _context.SaveChangesAsync(cancellationToken);

        return NoContent();
    }
}

