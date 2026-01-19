namespace ZoozyApi.Dtos
{
    public class PetWalkDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int DurationSeconds { get; set; }
        public double DistanceKm { get; set; }
        
        public List<PathPointDto> Path { get; set; } = new();
        public List<PetWalkItemDto> Pets { get; set; } = new();
        
        public DateTime Date { get; set; }
    }

    public class CreatePetWalkDto
    {
        public int UserId { get; set; }
        public int DurationSeconds { get; set; }
        public double DistanceKm { get; set; }
        public List<PathPointDto> Path { get; set; } = new();
        public List<PetWalkItemDto> Pets { get; set; } = new();
        public DateTime Date { get; set; }
    }

    public class PathPointDto
    {
        public double Lat { get; set; }
        public double Lng { get; set; }
    }

    public class PetWalkItemDto
    {
        public string Type { get; set; } = string.Empty;
    }
}
