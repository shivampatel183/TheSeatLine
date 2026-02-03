namespace TheSeatLine.Domain.Entities;

public sealed class Ticket
{
    public Guid Id { get; set; }
    public Guid TicketTypeId { get; set; }
    public Guid OrderId { get; set; }
    public Guid OwnerUserId { get; set; }
    public string Code { get; set; } = string.Empty;
    public TicketStatus Status { get; set; } = TicketStatus.Active;

    public TicketType? TicketType { get; set; }
    public Order? Order { get; set; }
    public User? OwnerUser { get; set; }
    public List<TicketTransfer> Transfers { get; set; } = new();
}
