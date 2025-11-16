# Supabase Persistent Volumes Configuration

## 📁 Volume Structure

All Supabase volumes are now configured with local-persist driver for true persistence across container restarts and recreations.

### Host Directory Structure
```
/opt/stacks/apps/database/supabase/
├── postgres_data/           # PostgreSQL database files
├── storage_data/           # User uploaded files and storage
└── kong_config/           # Kong API gateway configuration
    └── kong.yml           # Kong routing configuration
```

### Volume Mappings
| Volume Name | Container Path | Host Path | Purpose |
|------------|----------------|-----------|---------|
| `postgres_data` | `/var/lib/postgresql/data` | `/opt/stacks/apps/database/supabase/postgres_data` | PostgreSQL database storage |
| `storage_data` | `/var/lib/storage` | `/opt/stacks/apps/database/supabase/storage_data` | File uploads and storage |
| `kong_config` | `/var/lib/kong` | `/opt/stacks/apps/database/supabase/kong_config` | API gateway configuration |

## 🔧 Local-Persist Driver Benefits

1. **True Persistence**: Volumes survive container removal and Docker daemon restarts
2. **Explicit Location**: Data is stored in a predictable, accessible location on the host
3. **Easy Backup**: Simply backup `/opt/stacks/apps/database/supabase/` directory
4. **Migration Friendly**: Easy to move data between hosts
5. **Debugging**: Direct access to volume contents for troubleshooting

## 🚀 Setup Process

### 1. Install Local-Persist Plugin
```bash
# Run the setup script (includes plugin installation)
./setup-local-persist.sh

# Or install manually:
docker plugin install cwspear/docker-local-persist-volume-plugin:latest
docker plugin enable cwspear/docker-local-persist-volume-plugin:latest
```

### 2. Deploy Stack
```bash
# Deploy with automatic volume creation
./deploy.sh
```

The deploy script will automatically:
- Create the required directory structure
- Copy Kong configuration to persistent location
- Set proper permissions
- Deploy the stack with persistent volumes

## 📋 Volume Management

### Check Volume Status
```bash
# List all volumes
docker volume ls

# Inspect specific volume
docker volume inspect supabase_postgres_data
docker volume inspect supabase_storage_data
docker volume inspect supabase_kong_config
```

### Direct Access to Volume Data
```bash
# PostgreSQL data
sudo ls -la /opt/stacks/apps/database/supabase/postgres_data/

# Storage files
sudo ls -la /opt/stacks/apps/database/supabase/storage_data/

# Kong configuration
sudo cat /opt/stacks/apps/database/supabase/kong_config/kong.yml
```

### Manual Volume Creation (if needed)
```bash
# Create directories manually
sudo mkdir -p /opt/stacks/apps/database/supabase/{postgres_data,storage_data,kong_config}

# Set permissions
sudo chown -R $(id -u):$(id -g) /opt/stacks/apps/database/supabase/

# Copy Kong config
cp volumes/api/kong.yml /opt/stacks/apps/database/supabase/kong_config/kong.yml
```

## 💾 Backup Strategy

### Full Backup
```bash
# Stop stack
docker compose --env-file stack.env down

# Backup all volumes
sudo tar -czf supabase_volumes_backup_$(date +%Y%m%d).tar.gz \
  -C /opt/stacks/apps/database/supabase/ .

# Start stack
docker compose --env-file stack.env up -d
```

### Database-Only Backup (Hot Backup)
```bash
# Create SQL dump (while running)
./deploy.sh backup
```

### Restore from Backup
```bash
# Stop stack
docker compose --env-file stack.env down

# Restore volumes
sudo rm -rf /opt/stacks/apps/database/supabase/*
sudo tar -xzf supabase_volumes_backup_YYYYMMDD.tar.gz \
  -C /opt/stacks/apps/database/supabase/

# Start stack
docker compose --env-file stack.env up -d
```

## 🔄 Migration Between Hosts

### Export from Source Host
```bash
# Stop stack
docker compose --env-file stack.env down

# Create archive
sudo tar -czf supabase_migration.tar.gz \
  -C /opt/stacks/apps/database/ supabase/

# Copy archive to destination host
scp supabase_migration.tar.gz user@destination-host:/tmp/
```

### Import on Destination Host
```bash
# Install local-persist plugin
./setup-local-persist.sh

# Extract volumes
sudo tar -xzf /tmp/supabase_migration.tar.gz \
  -C /opt/stacks/apps/database/

# Deploy stack
./deploy.sh
```

## ⚠️ Important Notes

1. **Permissions**: The `/opt/stacks/apps/database/supabase/` directory requires proper ownership for Docker containers to access it

2. **Disk Space**: Monitor disk usage in `/opt/stacks/apps/database/supabase/` as PostgreSQL and storage data can grow significantly

3. **Plugin Dependency**: The local-persist plugin must be installed and enabled before deploying the stack

4. **Kong Config**: Any changes to Kong configuration should be made in `volumes/api/kong.yml` and then copied to the persistent location, or edit directly in `/opt/stacks/apps/database/supabase/kong_config/kong.yml`

## 🛠️ Troubleshooting

### Volume Not Found Error
```bash
# Ensure plugin is installed
docker plugin ls | grep local-persist

# Check directory exists and has correct permissions
ls -la /opt/stacks/apps/database/supabase/
```

### Permission Denied Errors
```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) /opt/stacks/apps/database/supabase/

# Fix permissions
sudo chmod -R 755 /opt/stacks/apps/database/supabase/
```

### Kong Configuration Issues
```bash
# Check Kong config file
sudo cat /opt/stacks/apps/database/supabase/kong_config/kong.yml

# Copy updated config
cp volumes/api/kong.yml /opt/stacks/apps/database/supabase/kong_config/kong.yml

# Restart Kong service
docker compose --env-file stack.env restart kong
```