# scripts/docker-stop.ps1
# Stop all Docker containers for TheSeatLine

Write-Host "🛑 Stopping TheSeatLine Platform..." -ForegroundColor Yellow

try {
    docker compose down
    Write-Host "✅ All containers stopped successfully." -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to stop containers." -ForegroundColor Red
    exit 1
}
