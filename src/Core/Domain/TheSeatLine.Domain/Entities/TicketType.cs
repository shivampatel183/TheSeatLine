namespace TheSeatLine.Domain.Entities;

public sealed class TicketType
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Capacity { get; set; }

    public Event? Event { get; set; }
    public List<Ticket> Tickets { get; set; } = new();
}
