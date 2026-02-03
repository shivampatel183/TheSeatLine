namespace TheSeatLine.Domain.Entities;

public sealed class TicketTransfer
{
    public Guid Id { get; set; }
    public Guid TicketId { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public TicketTransferStatus Status { get; set; } = TicketTransferStatus.Pending;
    public DateTimeOffset RequestedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? AcceptedAt { get; set; }

    public Ticket? Ticket { get; set; }
    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
}
