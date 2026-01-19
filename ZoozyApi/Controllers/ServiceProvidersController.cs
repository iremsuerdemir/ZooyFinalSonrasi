using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ZoozyApi.Data;
using ZoozyApi.Models;
using ServiceProviderModel = ZoozyApi.Models.ServiceProvider;

namespace ZoozyApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ServiceProvidersController : ControllerBase
{
    private readonly AppDbContext _context;

    public ServiceProvidersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ServiceProviderModel>>> GetAllAsync(CancellationToken cancellationToken)
    {
        // ServiceProvider tablosunu User tablosu ile join'le ve PhotoUrl bilgisini al
        var query = from sp in _context.ServiceProviders.AsNoTracking()
                    join u in _context.Users.AsNoTracking() on sp.FirebaseId equals u.FirebaseUid into userGroup
                    from user in userGroup.DefaultIfEmpty() // Left Join
                    orderby sp.UpdatedAt descending
                    select new
                    {
                        Provider = sp,
                        PhotoUrl = user != null ? user.PhotoUrl : null,
                        Slug = user != null ? user.Slug : null
                    };

        var resultList = await query.ToListAsync(cancellationToken);

        // User tablosundan gelen PhotoUrl ve Slug bilgilerini ServiceProvider nesnesine ekle
        var providers = resultList.Select(item =>
        {
            var p = item.Provider;
            p.PhotoUrl = item.PhotoUrl;
            p.Slug = item.Slug;
            return p;
        }).ToList();

        return Ok(providers);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ServiceProviderModel>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var provider = await _context.ServiceProviders
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (provider is null)
        {
            return NotFound();
        }

        return Ok(provider);
    }

    [HttpPost]
    public async Task<ActionResult<ServiceProviderModel>> CreateAsync(ServiceProviderModel provider, CancellationToken cancellationToken)
    {
        provider.Id = Guid.NewGuid();
        provider.CreatedAt = DateTime.UtcNow;
        provider.UpdatedAt = DateTime.UtcNow;

        _context.ServiceProviders.Add(provider);
        await _context.SaveChangesAsync(cancellationToken);

        return CreatedAtAction(nameof(GetByIdAsync), new { id = provider.Id }, provider);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateAsync(Guid id, ServiceProviderModel updated, CancellationToken cancellationToken)
    {
        var existing = await _context.ServiceProviders.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (existing is null)
        {
            return NotFound();
        }

        existing.Name = updated.Name;
        existing.ServiceType = updated.ServiceType;
        existing.Description = updated.Description;
        existing.Location = updated.Location;
        existing.ContactInfo = updated.ContactInfo;
        existing.Rating = updated.Rating;
        existing.OffersLiveTracking = updated.OffersLiveTracking;
        existing.OffersVideoCall = updated.OffersVideoCall;
        existing.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var existing = await _context.ServiceProviders.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (existing is null)
        {
            return NotFound();
        }

        _context.ServiceProviders.Remove(existing);
        await _context.SaveChangesAsync(cancellationToken);

        return NoContent();
    }
}

