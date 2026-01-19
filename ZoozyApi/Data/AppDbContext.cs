using Microsoft.EntityFrameworkCore;
using ZoozyApi.Models;
using ServiceProviderModel = ZoozyApi.Models.ServiceProvider;

namespace ZoozyApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<PetProfile> PetProfiles => Set<PetProfile>();
    public DbSet<ServiceProviderModel> ServiceProviders => Set<ServiceProviderModel>();
    public DbSet<ServiceRequest> ServiceRequests => Set<ServiceRequest>();
    public DbSet<FirebaseSyncLog> FirebaseSyncLogs => Set<FirebaseSyncLog>();
    public DbSet<User> Users => Set<User>();
    public DbSet<UserRequest> UserRequests => Set<UserRequest>();
    public DbSet<UserFavorite> UserFavorites => Set<UserFavorite>();
    public DbSet<UserComment> UserComments => Set<UserComment>();
    public DbSet<UserService> UserServices => Set<UserService>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<PetWalk> PetWalks => Set<PetWalk>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // PetProfile FirebaseId unique
        modelBuilder.Entity<PetProfile>()
            .HasIndex(p => p.FirebaseId)
            .IsUnique();

        // ServiceProvider FirebaseId unique
        modelBuilder.Entity<ServiceProviderModel>()
            .HasIndex(p => p.FirebaseId)
            .IsUnique();

        // Rating precision
        modelBuilder.Entity<ServiceProviderModel>()
            .Property(p => p.Rating)
            .HasPrecision(3, 2);

        // ServiceRequest FirebaseId unique
        modelBuilder.Entity<ServiceRequest>()
            .HasIndex(r => r.FirebaseId)
            .IsUnique();

        // ServiceRequest -> PetProfile (FK)
        modelBuilder.Entity<ServiceRequest>()
            .HasOne(r => r.PetProfile)
            .WithMany(p => p.ServiceRequests)
            .HasForeignKey(r => r.PetProfileId)
            .OnDelete(DeleteBehavior.Restrict);

        // User Email unique
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // User FirebaseUid unique (nullable olabilir)
        modelBuilder.Entity<User>()
            .HasIndex(u => u.FirebaseUid)
            .IsUnique()
            .HasFilter("[FirebaseUid] IS NOT NULL");

        // ServiceRequest -> ServiceProvider (FK)
        modelBuilder.Entity<ServiceRequest>()
            .HasOne(r => r.ServiceProvider)
            .WithMany(p => p.ServiceRequests)
            .HasForeignKey(r => r.ServiceProviderId)
            .OnDelete(DeleteBehavior.Restrict);

        // UserRequest -> User (FK)
        modelBuilder.Entity<UserRequest>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // UserFavorite -> User (FK)
        modelBuilder.Entity<UserFavorite>()
            .HasOne(f => f.User)
            .WithMany()
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // UserComment -> User (FK)
        modelBuilder.Entity<UserComment>()
            .HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // AuthorAvatar için NVARCHAR(MAX) kullan (base64 string çok uzun olabilir)
        modelBuilder.Entity<UserComment>()
            .Property(c => c.AuthorAvatar)
            .HasColumnType("nvarchar(max)");

        // UserPhoto için NVARCHAR(MAX) kullan (base64 string çok uzun olabilir)
        modelBuilder.Entity<UserRequest>()
            .Property(r => r.UserPhoto)
            .HasColumnType("nvarchar(max)");

        // UserService -> User (FK)
        modelBuilder.Entity<UserService>()
            .HasOne(s => s.User)
            .WithMany()
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Message -> Sender (FK)
        modelBuilder.Entity<Message>()
            .HasOne(m => m.Sender)
            .WithMany()
            .HasForeignKey(m => m.SenderId)
            .OnDelete(DeleteBehavior.Restrict);

        // Message -> Receiver (FK)
        modelBuilder.Entity<Message>()
            .HasOne(m => m.Receiver)
            .WithMany()
            .HasForeignKey(m => m.ReceiverId)
            .OnDelete(DeleteBehavior.Restrict);

        // Message -> Job (FK)
        modelBuilder.Entity<Message>()
            .HasOne(m => m.Job)
            .WithMany()
            .HasForeignKey(m => m.JobId)
            .OnDelete(DeleteBehavior.Restrict);

        // Notification -> User (FK)
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.User)
            .WithMany()
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notification -> RelatedUser (FK)
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.RelatedUser)
            .WithMany()
            .HasForeignKey(n => n.RelatedUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Notification -> RelatedJob (FK)
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.RelatedJob)
            .WithMany()
            .HasForeignKey(n => n.RelatedJobId)
            .OnDelete(DeleteBehavior.Restrict);

        // PetProfile -> User (FK)
        modelBuilder.Entity<PetProfile>()
            .HasOne(p => p.User)
            .WithMany(u => u.PetProfiles)
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
