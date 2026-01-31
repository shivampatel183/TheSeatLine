#!/bin/bash
# scripts/database-backup.sh
# Database backup script

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/eventbooking_backup_$TIMESTAMP.sql"

echo "💾 Creating database backup..."

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Create backup
docker-compose exec -T postgres pg_dump \
    -U eventbooking \
    -d EventBookingDb \
    --schema=eventbooking \
    --clean \
    --if-exists \
    --verbose \
    > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

echo "✅ Backup created: ${BACKUP_FILE}.gz"
echo "📦 Backup size: $(du -h ${BACKUP_FILE}.gz | cut -f1)"