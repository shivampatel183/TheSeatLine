#!/bin/bash
# docker/api/entrypoint.dev.sh

set -e

echo "Starting EventBooking API Development Environment..."

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
while ! nc -z postgres 5432; do
  sleep 1
done
echo "PostgreSQL is ready!"

# Wait for Redis
echo "Waiting for Redis..."
while ! nc -z redis 6379; do
  sleep 1
done
echo "Redis is ready!"

# Wait for RabbitMQ
echo "Waiting for RabbitMQ..."
while ! nc -z rabbitmq 5672; do
  sleep 1
done
echo "RabbitMQ is ready!"

# Run database migrations
echo "Running database migrations..."
dotnet ef database update --project src/Infrastructure/Persistence --startup-project src/Presentation/API

# Seed database if needed
echo "Seeding database..."
dotnet run --project src/Presentation/API seed

# Start the application with hot reload
echo "Starting application..."
exec dotnet watch run --project src/Presentation/API --urls "http://0.0.0.0:5000;https://0.0.0.0:5001"