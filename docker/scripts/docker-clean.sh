#!/bin/bash
# scripts/docker-clean.sh
# Clean Docker containers and volumes

set -e

read -p "⚠️  This will remove all containers, volumes, and images. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Operation cancelled."
    exit 1
fi

echo "🧹 Cleaning Docker environment..."

docker-compose down -v
docker image prune -a -f
docker volume prune -f
docker network prune -f

rm -rf .docker/*

echo "✅ Docker environment cleaned."
