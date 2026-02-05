using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using TheSeatLine.Application.Auth;
using TheSeatLine.Application.Auth.Models;
using TheSeatLine.Application.Auth.Options;
using TheSeatLine.Domain.Entities;
using TheSeatLine.Identity;


var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDbContext<TheSeatLine.Persistence.TheSeatLineDbContext>(options =>
    options.UseNpgsql(connectionString));
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddSingleton<IPasswordHasher<User>, PasswordHasher<User>>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<TheSeatLine.Persistence.TheSeatLineDbContext>();
    dbContext.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();


app.MapPost("/auth/register", async (RegisterRequest request, IAuthService authService, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password) ||
        string.IsNullOrWhiteSpace(request.DisplayName))
    {
        return Results.BadRequest(new { message = "Email, display name, and password are required." });
    }

    var result = await authService.RegisterAsync(request, cancellationToken);
    return result is null
        ? Results.Conflict(new { message = "Email already registered." })
        : Results.Ok(result);
})
.WithName("Register");

app.MapPost("/auth/login", async (LoginRequest request, IAuthService authService, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email and password are required." });
    }

    var result = await authService.LoginAsync(request, cancellationToken);
    return result is null
        ? Results.Unauthorized()
        : Results.Ok(result);
})
.WithName("Login");

app.MapPost("/auth/register", async (RegisterRequest request, IAuthService authService, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password) ||
        string.IsNullOrWhiteSpace(request.DisplayName))
    {
        return Results.BadRequest(new { message = "Email, display name, and password are required." });
    }

    var result = await authService.RegisterAsync(request, cancellationToken);
    return result is null
        ? Results.Conflict(new { message = "Email already registered." })
        : Results.Ok(result);
})
.WithName("Register");

app.MapPost("/auth/login", async (LoginRequest request, IAuthService authService, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email and password are required." });
    }

    var result = await authService.LoginAsync(request, cancellationToken);
    return result is null
        ? Results.Unauthorized()
        : Results.Ok(result);
})
.WithName("Login");

app.Run();

