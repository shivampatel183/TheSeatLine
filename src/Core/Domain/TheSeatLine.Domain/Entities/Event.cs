namespace TheSeatLine.Domain.Entities;

public sealed class Event
{
    public Guid Id { get; set; }
    public Guid OrganizerId { get; set; }
    public Guid VenueId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset StartsAt { get; set; }
    public DateTimeOffset EndsAt { get; set; }
    public EventStatus Status { get; set; } = EventStatus.Draft;

    public Organizer? Organizer { get; set; }
    public Venue? Venue { get; set; }
    public List<TicketType> TicketTypes { get; set; } = new();
}
