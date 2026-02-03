namespace TheSeatLine.Application.Auth.Models;

public sealed record RegisterRequest(string Email, string DisplayName, string Password);
