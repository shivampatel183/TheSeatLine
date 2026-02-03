namespace TheSeatLine.Domain.Entities;

public sealed class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string NormalizedEmail { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public Organizer? OrganizerProfile { get; set; }
    public List<Order> Orders { get; set; } = new();
    public List<Ticket> OwnedTickets { get; set; } = new();
}
