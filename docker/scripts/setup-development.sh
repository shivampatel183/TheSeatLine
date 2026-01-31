#!/bin/bash
# scripts/setup-development.sh
# Complete development environment setup

set -e

echo "🛠️  Setting up EventBooking Development Environment..."

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Desktop."
    exit 1
fi

# Check .NET SDK
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK is not installed. Please install .NET 8 SDK."
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+."
    exit 1
fi

# Check Angular CLI
if ! command -v ng &> /dev/null; then
    echo "📦 Installing Angular CLI..."
    npm install -g @angular/cli@17
fi

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration."
fi

# Generate self-signed certificates for development
echo "🔐 Generating development certificates..."
mkdir -p .docker/certs
openssl req -x509 -newkey rsa:4096 -keyout .docker/certs/aspnetcore.key \
    -out .docker/certs/aspnetcore.crt -days 365 -nodes \
    -subj "/C=US/ST=State/L=City/O=EventBooking/CN=localhost"

# Convert to PFX for .NET
openssl pkcs12 -export -out .docker/certs/aspnetcore.pfx \
    -inkey .docker/certs/aspnetcore.key \
    -in .docker/certs/aspnetcore.crt -passout pass:development

# Trust the certificate on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Adding certificate to macOS keychain..."
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain .docker/certs/aspnetcore.crt
fi

# Build Docker images
echo "🐳 Building Docker images..."
docker-compose build

# Start services
echo "🚀 Starting services..."
./scripts/docker-start.sh

# Install .NET tools
echo "📦 Installing .NET tools..."
dotnet tool restore

# Setup git hooks
echo "🔧 Setting up git hooks..."
if [ -d .git ]; then
    cp scripts/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
fi

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Run './scripts/docker-start.sh' to start all services"
echo "3. Access the application at http://localhost:4200"
echo ""
echo "For more information, check the README.md file."