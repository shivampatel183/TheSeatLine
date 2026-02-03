namespace TheSeatLine.Domain.Entities;

public sealed class Organizer
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;

    public User? User { get; set; }
    public List<Event> Events { get; set; } = new();
}
