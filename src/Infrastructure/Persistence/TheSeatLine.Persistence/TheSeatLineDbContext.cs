using Microsoft.EntityFrameworkCore;
using TheSeatLine.Domain.Entities;

namespace TheSeatLine.Persistence;

public sealed class TheSeatLineDbContext : DbContext
{
    public TheSeatLineDbContext(DbContextOptions<TheSeatLineDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Organizer> Organizers => Set<Organizer>();
    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<TicketType> TicketTypes => Set<TicketType>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Ticket> Tickets => Set<Ticket>();
    public DbSet<TicketTransfer> TicketTransfers => Set<TicketTransfer>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(builder =>
        {
            builder.HasKey(user => user.Id);
            builder.Property(user => user.Email).IsRequired().HasMaxLength(256);
            builder.Property(user => user.NormalizedEmail).IsRequired().HasMaxLength(256);
            builder.Property(user => user.DisplayName).IsRequired().HasMaxLength(200);
            builder.Property(user => user.PasswordHash).IsRequired().HasMaxLength(500);
            builder.HasIndex(user => user.Email).IsUnique();
            builder.HasIndex(user => user.NormalizedEmail).IsUnique();
        });

        modelBuilder.Entity<Organizer>(builder =>
        {
            builder.HasKey(organizer => organizer.Id);
            builder.Property(organizer => organizer.DisplayName).IsRequired().HasMaxLength(200);
            builder.Property(organizer => organizer.ContactEmail).IsRequired().HasMaxLength(256);
            builder.HasIndex(organizer => organizer.UserId).IsUnique();
            builder.HasOne(organizer => organizer.User)
                .WithOne(user => user.OrganizerProfile)
                .HasForeignKey<Organizer>(organizer => organizer.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Venue>(builder =>
        {
            builder.HasKey(venue => venue.Id);
            builder.Property(venue => venue.Name).IsRequired().HasMaxLength(200);
            builder.Property(venue => venue.City).IsRequired().HasMaxLength(120);
            builder.Property(venue => venue.State).IsRequired().HasMaxLength(120);
            builder.Property(venue => venue.Country).IsRequired().HasMaxLength(120);
            builder.Property(venue => venue.PostalCode).IsRequired().HasMaxLength(40);
        });

        modelBuilder.Entity<Event>(builder =>
        {
            builder.HasKey(eventEntity => eventEntity.Id);
            builder.Property(eventEntity => eventEntity.Title).IsRequired().HasMaxLength(200);
            builder.Property(eventEntity => eventEntity.Description).HasMaxLength(4000);
            builder.HasIndex(eventEntity => eventEntity.StartsAt);
            builder.HasOne(eventEntity => eventEntity.Organizer)
                .WithMany(organizer => organizer.Events)
                .HasForeignKey(eventEntity => eventEntity.OrganizerId)
                .OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(eventEntity => eventEntity.Venue)
                .WithMany(venue => venue.Events)
                .HasForeignKey(eventEntity => eventEntity.VenueId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TicketType>(builder =>
        {
            builder.HasKey(ticketType => ticketType.Id);
            builder.Property(ticketType => ticketType.Name).IsRequired().HasMaxLength(160);
            builder.Property(ticketType => ticketType.Price).HasPrecision(18, 2);
            builder.HasOne(ticketType => ticketType.Event)
                .WithMany(eventEntity => eventEntity.TicketTypes)
                .HasForeignKey(ticketType => ticketType.EventId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Order>(builder =>
        {
            builder.HasKey(order => order.Id);
            builder.Property(order => order.TotalAmount).HasPrecision(18, 2);
            builder.HasIndex(order => order.CreatedAt);
            builder.HasOne(order => order.User)
                .WithMany(user => user.Orders)
                .HasForeignKey(order => order.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Ticket>(builder =>
        {
            builder.HasKey(ticket => ticket.Id);
            builder.Property(ticket => ticket.Code).IsRequired().HasMaxLength(80);
            builder.HasIndex(ticket => ticket.Code).IsUnique();
            builder.HasOne(ticket => ticket.TicketType)
                .WithMany(ticketType => ticketType.Tickets)
                .HasForeignKey(ticket => ticket.TicketTypeId)
                .OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(ticket => ticket.Order)
                .WithMany(order => order.Tickets)
                .HasForeignKey(ticket => ticket.OrderId)
                .OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(ticket => ticket.OwnerUser)
                .WithMany(user => user.OwnedTickets)
                .HasForeignKey(ticket => ticket.OwnerUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<TicketTransfer>(builder =>
        {
            builder.HasKey(transfer => transfer.Id);
            builder.HasIndex(transfer => transfer.ExpiresAt);
            builder.HasOne(transfer => transfer.Ticket)
                .WithMany(ticket => ticket.Transfers)
                .HasForeignKey(transfer => transfer.TicketId)
                .OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(transfer => transfer.FromUser)
                .WithMany()
                .HasForeignKey(transfer => transfer.FromUserId)
                .OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(transfer => transfer.ToUser)
                .WithMany()
                .HasForeignKey(transfer => transfer.ToUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
