# scripts/docker-start.ps1
# Start all Docker containers for TheSeatLine

Write-Host "🚀 Starting TheSeatLine Platform..." -ForegroundColor Cyan

# ================================
# LOAD ENV FILE
# ================================
if (Test-Path ".env") {
    Write-Host "📄 Loading environment variables from .env"
    Get-Content .env | ForEach-Object {
        if ($_ -and -not $_.StartsWith("#")) {
            $pair = $_ -split "=", 2
            if ($pair.Length -eq 2) {
                [System.Environment]::SetEnvironmentVariable($pair[0], $pair[1])
            }
        }
    }
}

# ================================
# CREATE REQUIRED DIRECTORIES
# ================================
Write-Host "📁 Ensuring Docker data directories exist..."
$dirs = @(
    ".docker/postgres-data",
    ".docker/redis-data",
    ".docker/rabbitmq-data",
    ".docker/seq-data"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# ================================
# CHECK DOCKER
# ================================
Write-Host "🐳 Checking Docker status..."
try {
    docker info | Out-Null
} catch {
    Write-Host "❌ Docker is not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# ================================
# BUILD & START
# ================================
Write-Host "📦 Building and starting containers..."
docker compose up -d --build

# ================================
# WAIT FOR SERVICES
# ================================
Write-Host "⏳ Waiting for services to be ready..."

# PostgreSQL
Write-Host "  📊 Waiting for PostgreSQL..."
while (-not (docker compose exec -T postgres pg_isready -U theseatline 2>$null)) {
    Start-Sleep -Seconds 2
}
Write-Host "  ✅ PostgreSQL ready"

# Redis
Write-Host "  🔴 Waiting for Redis..."
while (-not (docker compose exec -T redis redis-cli ping 2>$null | Select-String "PONG")) {
    Start-Sleep -Seconds 2
}
Write-Host "  ✅ Redis ready"

# RabbitMQ
Write-Host "  🐰 Waiting for RabbitMQ..."
while (-not (docker compose exec -T rabbitmq rabbitmq-diagnostics ping 2>$null)) {
    Start-Sleep -Seconds 2
}
Write-Host "  ✅ RabbitMQ ready"

# Seq
Write-Host "  📝 Waiting for Seq..."
while (-not (Invoke-WebRequest -Uri "http://localhost:8081" -UseBasicParsing -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 2
}
Write-Host "  ✅ Seq ready"

# ================================
# STATUS
# ================================
Write-Host ""
Write-Host "📊 Service Status"
Write-Host "------------------"
docker compose ps

# ================================
# ACCESS INFO
# ================================
Write-Host ""
Write-Host "🌐 Access URLs"
Write-Host "--------------"
Write-Host "PostgreSQL      : localhost:5432"
Write-Host "Redis           : localhost:6379"
Write-Host "RabbitMQ Mgmt   : http://localhost:15672"
Write-Host "Seq Logs        : http://localhost:8081"
Write-Host "API             : http://localhost:5000"
Write-Host "Angular App     : http://localhost:4200"

Write-Host ""
Write-Host "🔐 Default Credentials"
Write-Host "----------------------"
Write-Host "PostgreSQL : theseatline / $env:POSTGRES_PASSWORD"
Write-Host "RabbitMQ   : theseatline / $env:RABBITMQ_PASSWORD"

Write-Host ""
Write-Host "✅ TheSeatLine Platform is READY!" -ForegroundColor Green
Write-Host "📁 Docker data directory: .docker/"
