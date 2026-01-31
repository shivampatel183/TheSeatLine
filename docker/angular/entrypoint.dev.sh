#!/bin/bash
# docker/angular/entrypoint.dev.sh

set -e

echo "Starting EventBooking Angular Development Environment..."

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
  echo "Installing npm dependencies..."
  npm ci --legacy-peer-deps
fi

# Start Angular development server
echo "Starting Angular development server..."
exec ng serve --host 0.0.0.0 --port 4200 --disable-host-check --poll 2000