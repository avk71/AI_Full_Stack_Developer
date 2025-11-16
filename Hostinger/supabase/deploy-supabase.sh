#!/bin/bash
# deploy-supabase.sh - Deploy Supabase stack with proper error handling
# This script handles Docker login and deployment with retries

set -e

echo "🚀 Deploying Supabase Stack..."
echo "=============================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found in current directory"
    echo "Please run this script from the supabase directory"
    exit 1
fi

# Check if .env file exists
if [ ! -f "stack.env" ]; then
    echo "❌ Error: stack.env file not found"
    echo "Please ensure stack.env is present with all required variables"
    exit 1
fi

# Load environment variables
echo "📋 Loading environment variables from stack.env..."
export $(grep -v '^#' stack.env | xargs)

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker and try again"
    exit 1
fi

# Check Docker login status
echo "🔐 Checking Docker Hub authentication..."
if ! docker info | grep -q "Username:"; then
    echo "⚠️  Not logged into Docker Hub. Attempting login..."
    echo "This will help avoid rate limiting issues."
    if ! docker login; then
        echo "❌ Docker login failed. Continuing anyway..."
    fi
fi

# Check if local-persist plugin is installed
echo "🔌 Checking local-persist plugin..."
if ! docker plugin ls | grep -q "local-persist"; then
    echo "📦 Installing local-persist plugin for volume management..."
    if ! docker plugin install --grant-all-permissions cwspear/docker-local-persist-volume-plugin:latest; then
        echo "❌ Failed to install local-persist plugin"
        echo "Please install manually: docker plugin install --grant-all-permissions cwspear/docker-local-persist-volume-plugin:latest"
        exit 1
    fi
fi

# Create volume directories
echo "📁 Creating volume directories..."
sudo mkdir -p /opt/stacks/apps/database/supabase/{postgres_data,storage_data,kong_config}
sudo chown -R $USER:$USER /opt/stacks/apps/database/supabase/

# Pull all images first to check for issues
echo "📥 Pre-pulling Docker images to avoid deployment timeouts..."
docker-compose --env-file stack.env pull || {
    echo "⚠️  Some images failed to pull. This might be due to:"
    echo "   - Network connectivity issues"
    echo "   - Docker Hub rate limiting"
    echo "   - Image availability problems"
    echo ""
    echo "Continuing with deployment - Docker will try to pull missing images..."
}

# Deploy the stack
echo "🔄 Deploying Supabase stack..."
echo "This may take a few minutes on first run..."

# Use docker-compose with explicit env file
if docker-compose --env-file stack.env up -d; then
    echo ""
    echo "🎉 Supabase stack deployed successfully!"
    echo "======================================"
    echo ""
    echo "📊 Service Status:"
    docker-compose --env-file stack.env ps
    echo ""
    echo "🌐 Access URLs (via VPN only):"
    echo "   • Supabase Studio: http://${amnezia}:3000"
    echo "   • API Gateway: http://${amnezia}:8000"
    echo "   • Analytics: http://${amnezia}:4000"
    echo "   • PostgreSQL: ${amnezia}:5432"
    echo ""
    echo "🔧 Next Steps:"
    echo "   1. Connect via your Amnezia VPN"
    echo "   2. Access Studio at http://${amnezia}:3000"
    echo "   3. Use API endpoint: http://${amnezia}:8000"
    echo ""
    echo "📚 Documentation and credentials are in stack.env"
else
    echo ""
    echo "❌ Deployment failed!"
    echo "=================="
    echo ""
    echo "🔍 Troubleshooting steps:"
    echo "   1. Check the logs: docker-compose --env-file stack.env logs"
    echo "   2. Verify environment variables in stack.env"
    echo "   3. Ensure all required ports are free"
    echo "   4. Check UFW firewall rules"
    echo ""
    echo "📋 Current container status:"
    docker-compose --env-file stack.env ps -a
    exit 1
fi