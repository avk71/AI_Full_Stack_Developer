#!/bin/bash
# =============================================
# Database Backup Script for Supabase
# =============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
POSTGRES_CONTAINER="supabase_postgres_17"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p $BACKUP_DIR

# Load environment variables
if [ -f "stack.env" ]; then
    source stack.env
else
    print_error "stack.env file not found!"
    exit 1
fi

# Function to create full database backup
backup_full() {
    print_status "Creating full database backup..."

    BACKUP_FILE="$BACKUP_DIR/supabase_full_backup_$TIMESTAMP.sql"

    if docker exec $POSTGRES_CONTAINER pg_dumpall -U $POSTGRES_USER > "$BACKUP_FILE"; then
        print_success "Full backup created: $BACKUP_FILE"

        # Compress the backup
        gzip "$BACKUP_FILE"
        print_success "Backup compressed: ${BACKUP_FILE}.gz"
    else
        print_error "Failed to create full backup"
        exit 1
    fi
}

# Function to create schema-only backup
backup_schema() {
    print_status "Creating schema-only backup..."

    BACKUP_FILE="$BACKUP_DIR/supabase_schema_$TIMESTAMP.sql"

    if docker exec $POSTGRES_CONTAINER pg_dump -U $POSTGRES_USER -s $POSTGRES_DB > "$BACKUP_FILE"; then
        print_success "Schema backup created: $BACKUP_FILE"
        gzip "$BACKUP_FILE"
        print_success "Schema backup compressed: ${BACKUP_FILE}.gz"
    else
        print_error "Failed to create schema backup"
        exit 1
    fi
}

# Function to backup specific schema
backup_vectors() {
    print_status "Creating vectors schema backup..."

    BACKUP_FILE="$BACKUP_DIR/supabase_vectors_$TIMESTAMP.sql"

    if docker exec $POSTGRES_CONTAINER pg_dump -U $POSTGRES_USER -n vectors $POSTGRES_DB > "$BACKUP_FILE"; then
        print_success "Vectors schema backup created: $BACKUP_FILE"
        gzip "$BACKUP_FILE"
        print_success "Vectors backup compressed: ${BACKUP_FILE}.gz"
    else
        print_error "Failed to create vectors schema backup"
        exit 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups (keeping last 30 days)..."

    find $BACKUP_DIR -name "*.gz" -type f -mtime +30 -delete

    print_success "Old backups cleaned up"
}

# Function to list backups
list_backups() {
    print_status "Available backups:"

    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        ls -lah $BACKUP_DIR/*.gz 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' | column -t
    else
        print_warning "No backups found in $BACKUP_DIR"
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file=$1

    if [ -z "$backup_file" ]; then
        print_error "Please specify a backup file to restore"
        list_backups
        exit 1
    fi

    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi

    print_warning "This will restore the database from: $backup_file"
    print_warning "This operation will OVERWRITE the current database!"
    read -p "Are you sure you want to continue? (y/N): " confirm

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Restore cancelled"
        exit 0
    fi

    print_status "Restoring from backup: $backup_file"

    # Decompress if needed
    if [[ $backup_file == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB
    else
        docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB < "$backup_file"
    fi

    if [ $? -eq 0 ]; then
        print_success "Database restored successfully"
    else
        print_error "Failed to restore database"
        exit 1
    fi
}

# Main script logic
case "${1:-}" in
    full|backup)
        backup_full
        cleanup_old_backups
        ;;
    schema)
        backup_schema
        ;;
    vectors)
        backup_vectors
        ;;
    list|ls)
        list_backups
        ;;
    restore)
        restore_backup "$2"
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    help|--help|-h)
        echo "Supabase Database Backup Script"
        echo
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo
        echo "Commands:"
        echo "  full      - Create full database backup (default)"
        echo "  schema    - Create schema-only backup"
        echo "  vectors   - Create vectors schema backup"
        echo "  list      - List available backups"
        echo "  restore   - Restore from backup file"
        echo "  cleanup   - Remove old backups (30+ days)"
        echo "  help      - Show this help message"
        echo
        echo "Examples:"
        echo "  $0                                    # Full backup"
        echo "  $0 full                              # Full backup"
        echo "  $0 schema                            # Schema only"
        echo "  $0 vectors                           # Vectors schema only"
        echo "  $0 list                              # List backups"
        echo "  $0 restore backups/backup_file.gz    # Restore from file"
        ;;
    *)
        backup_full
        cleanup_old_backups
        ;;
esac