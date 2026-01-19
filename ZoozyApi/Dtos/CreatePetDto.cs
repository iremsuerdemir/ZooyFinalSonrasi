using System.ComponentModel.DataAnnotations;

namespace ZoozyApi.Dtos;

public class CreatePetDto
{
    [Required]
    [MaxLength(256)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(128)]
    public string Species { get; set; } = string.Empty;

    [MaxLength(128)]
    public string? Breed { get; set; }

    public int? Age { get; set; }

    [MaxLength(50)]
    public string? Weight { get; set; }

    [MaxLength(256)]
    public string? VaccinationStatus { get; set; }

    public string? HealthNotes { get; set; }

    [MaxLength(256)]
    public string OwnerName { get; set; } = string.Empty;

    [MaxLength(256)]
    public string OwnerContact { get; set; } = string.Empty;
}

