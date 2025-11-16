#!/bin/bash

# Supabase Reset and Deploy Script
# This script performs complete cleanup and redeployment of Supabase stack

set -e  # Exit on any error

echo "🧹 Starting Supabase cleanup and deployment..."

# Step 1: Stop all containers if running
echo "📦 Stopping Supabase containers..."
#docker-compose down --remove-orphans 2>/dev/null || true

# Step 2: Remove persistent folders
echo "🗂️  Removing persistent folders..."
sudo rm -rf /opt/stacks/apps/database/supabase/postgres_data
sudo rm -rf /opt/stacks/apps/database/supabase/storage_data
sudo rm -rf /opt/stacks/apps/database/supabase/kong_config
sudo rm -rf /opt/stacks/apps/database/supabase/init

# Create directories with correct ownership
echo "📁 Creating fresh directories..."
sudo mkdir -p /opt/stacks/apps/database/supabase/postgres_data
sudo mkdir -p /opt/stacks/apps/database/supabase/storage_data
sudo mkdir -p /opt/stacks/apps/database/supabase/kong_config
sudo mkdir -p /opt/stacks/apps/database/supabase/init

# Set correct ownership (PostgreSQL runs as user 70)
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/postgres_data
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/storage_data
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/init

# Step 3: Remove PostgreSQL Docker volumes
echo "💾 Removing PostgreSQL Docker volumes..."
docker volume rm supabase_postgres_data 2>/dev/null || echo "  ✓ supabase_postgres_data already removed"
docker volume rm supabase_storage_data 2>/dev/null || echo "  ✓ supabase_storage_data already removed"
docker volume rm supabase_kong_config 2>/dev/null || echo "  ✓ supabase_kong_config already removed"

# Step 4: Copy all 6 init scripts to /opt
echo "📋 Copying init scripts to /opt..."
sudo cp ./init/00-create-supabase-admin.sql /opt/stacks/apps/database/supabase/init/
sudo cp ./init/01-initial-schema.sql /opt/stacks/apps/database/supabase/init/
sudo cp ./init/02-auth-schema.sql /opt/stacks/apps/database/supabase/init/
sudo cp ./init/03-storage-schema.sql /opt/stacks/apps/database/supabase/init/
sudo cp ./init/04-vector-schema.sql /opt/stacks/apps/database/supabase/init/
sudo cp ./init/05-seed-data.sql /opt/stacks/apps/database/supabase/init/

# Step 5: Copy Kong configuration
echo "🔧 Copying Kong configuration..."
sudo cp ./kong.yml /opt/stacks/apps/database/supabase/kong_config/

# Set correct ownership for init scripts
sudo chown -R root:root /opt/stacks/apps/database/supabase/init/
sudo chmod 644 /opt/stacks/apps/database/supabase/init/*.sql
sudo chown -R root:root /opt/stacks/apps/database/supabase/kong_config/
sudo chmod 644 /opt/stacks/apps/database/supabase/kong_config/kong.yml

echo "✅ Cleanup completed successfully!"
echo ""
echo "🚀 Starting Supabase stack..."
# docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
# sleep 10

echo ""
echo "📊 Container status:"
# docker-compose ps

echo ""
echo "🔍 PostgreSQL logs (last 10 lines):"
# docker logs supabase_postgres_17 --tail 10

echo ""
echo "✅ Deployment script completed!"
echo ""
echo "🌐 Services should be available at:"
echo "  - Supabase Studio: http://172.29.172.1:3000"
echo "  - PostgreSQL: 172.29.172.1:5432"
echo "  - API Gateway: http://172.29.172.1:8000"
echo ""
echo "🔐 Admin credentials:"
echo "  - User: supabase_admin"
echo "  - Password: HWcns2tWSTXEWRwUGTtsTDfBM9vyCMdn"