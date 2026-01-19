using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ZoozyApi.Models
{
    public class PetWalk
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User? User { get; set; }

        public int DurationSeconds { get; set; }
        
        public double DistanceKm { get; set; }
        
        // JSON string to store list of path coordinates
        public string PathJson { get; set; } = string.Empty;

        // JSON string to store list of pets
        public string PetsJson { get; set; } = string.Empty;

        public DateTime Date { get; set; } = DateTime.UtcNow;
    }
}
