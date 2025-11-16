#!/bin/bash

# Supabase Stack Deployment Script for Portainer
# This script helps deploy and manage your Supabase stack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"

    # Check if local-persist plugin is installed
    if ! docker plugin ls | grep -q local-persist; then
        print_error "local-persist Docker plugin is not installed!"
        print_error "Please install it first:"
        print_error "  docker plugin install cwspear/docker-local-persist-volume-plugin:latest"
        print_error "  docker plugin enable cwspear/docker-local-persist-volume-plugin:latest"
        exit 1
    fi
    print_success "local-persist plugin is available"
}

# Generate secure passwords and keys
generate_secrets() {
    print_status "Generating secure passwords and keys..."

    # Generate secure PostgreSQL password
    POSTGRES_PASSWORD=$(openssl rand -hex 32)

    # Generate JWT secret (must be at least 32 characters)
    JWT_SECRET=$(openssl rand -hex 32)

    # Generate Logflare API key
    LOGFLARE_API_KEY=$(openssl rand -hex 32)

    print_success "Secrets generated successfully"

    cat > .env.generated << EOF
# Generated secure passwords - Keep these safe!
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
JWT_SECRET=${JWT_SECRET}
LOGFLARE_API_KEY=${LOGFLARE_API_KEY}
EOF

    print_warning "Generated passwords saved to .env.generated - Please back this up!"
}

# Update stack.env with generated secrets
update_env_file() {
    if [ -f ".env.generated" ]; then
        source .env.generated

        # Update stack.env with generated values
        sed -i "s/supabase_postgres_password_2024/${POSTGRES_PASSWORD}/" stack.env
        sed -i "s/your_super_secret_jwt_token_with_at_least_32_characters_long/${JWT_SECRET}/" stack.env
        sed -i "s/your_super_secret_logflare_api_key_2024/${LOGFLARE_API_KEY}/" stack.env

        print_success "Environment file updated with generated secrets"
    else
        print_warning "No generated secrets found, using defaults from stack.env"
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."

    # Create local-persist volume directories
    sudo mkdir -p /opt/stacks/apps/database/supabase/postgres_data
    sudo mkdir -p /opt/stacks/apps/database/supabase/storage_data
    sudo mkdir -p /opt/stacks/apps/database/supabase/kong_config

    # Set proper ownership (Docker needs access)
    sudo chown -R $(id -u):$(id -g) /opt/stacks/apps/database/supabase/

    # Copy Kong configuration to the persistent volume location
    if [ -f "volumes/api/kong.yml" ]; then
        cp volumes/api/kong.yml /opt/stacks/apps/database/supabase/kong_config/kong.yml
        print_success "Kong configuration copied to persistent volume"
    else
        print_error "Kong configuration file not found at volumes/api/kong.yml"
        exit 1
    fi

    print_success "Volume directories created"
}

# Set proper permissions
set_permissions() {
    print_status "Setting proper permissions..."

    # Ensure volume directories are accessible
    sudo chmod -R 755 /opt/stacks/apps/database/supabase/

    # Ensure Kong config is readable
    sudo chmod 644 /opt/stacks/apps/database/supabase/kong_config/kong.yml

    print_success "Permissions set"
}

# Validate configuration
validate_config() {
    print_status "Validating configuration..."

    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found!"
        exit 1
    fi

    if [ ! -f "stack.env" ]; then
        print_error "stack.env not found!"
        exit 1
    fi

    print_success "Configuration validated"
}

# Display port information
show_port_info() {
    print_status "Port Configuration:"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ Service               │ Internal │ External │ Purpose    │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ PostgreSQL            │ 5432     │ 5433     │ Database   │"
    echo "│ Supabase Studio       │ 3000     │ 8080     │ Web UI     │"
    echo "│ Kong API Gateway      │ 8000     │ 8000     │ API        │"
    echo "│ Kong HTTPS            │ 8443     │ 8443     │ API SSL    │"
    echo "│ Analytics (Logflare)  │ 4000     │ 4001     │ Logs       │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo
    print_warning "Make sure these ports are available on your host system!"
}

# Display connection information
show_connection_info() {
    print_success "Deployment completed! Here's how to connect:"
    echo
    echo "🌐 Supabase Studio (Web UI):"
    echo "   http://your-server-ip:8080"
    echo
    echo "🗃️  PostgreSQL (DBeaver/pgAdmin):"
    echo "   Host: your-server-ip"
    echo "   Port: 5433"
    echo "   Database: postgres"
    echo "   Username: postgres"
    echo "   Password: (check stack.env or .env.generated)"
    echo
    echo "🔧 API Endpoints:"
    echo "   REST API: http://your-server-ip:8000/rest/v1/"
    echo "   Auth API: http://your-server-ip:8000/auth/v1/"
    echo "   Realtime: ws://your-server-ip:8000/realtime/v1/"
    echo
    echo "📊 Analytics:"
    echo "   Logflare: http://your-server-ip:4001"
    echo
}

# Display UFW rules
show_ufw_rules() {
    print_status "UFW Firewall Rules:"
    echo "Run these commands on your Ubuntu server:"
    echo
    echo "# Allow PostgreSQL (for DBeaver)"
    echo "sudo ufw allow 5433/tcp comment 'Supabase PostgreSQL'"
    echo
    echo "# Allow Supabase Studio"
    echo "sudo ufw allow 8080/tcp comment 'Supabase Studio'"
    echo
    echo "# Allow API Gateway"
    echo "sudo ufw allow 8000/tcp comment 'Supabase API HTTP'"
    echo "sudo ufw allow 8443/tcp comment 'Supabase API HTTPS'"
    echo
    echo "# Allow Analytics"
    echo "sudo ufw allow 4001/tcp comment 'Supabase Analytics'"
    echo
    echo "# Check UFW status"
    echo "sudo ufw status numbered"
    echo
}

# Main deployment function
deploy() {
    print_status "Starting Supabase deployment..."

    check_docker
    validate_config
    create_directories

    # Ask if user wants to generate new secrets
    read -p "Generate new secure passwords? (y/N): " generate_new
    if [[ $generate_new =~ ^[Yy]$ ]]; then
        generate_secrets
        update_env_file
    fi

    set_permissions
    show_port_info

    # Ask for confirmation
    read -p "Continue with deployment? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi

    print_status "Deploying stack..."

    # Deploy using Docker Compose
    docker compose --env-file stack.env up -d

    print_success "Stack deployed successfully!"

    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 30

    show_connection_info
    show_ufw_rules
}

# Function to stop the stack
stop() {
    print_status "Stopping Supabase stack..."
    docker compose --env-file stack.env down
    print_success "Stack stopped"
}

# Function to restart the stack
restart() {
    print_status "Restarting Supabase stack..."
    docker compose --env-file stack.env restart
    print_success "Stack restarted"
}

# Function to show logs
logs() {
    docker compose --env-file stack.env logs -f
}

# Function to show status
status() {
    print_status "Supabase Stack Status:"
    docker compose --env-file stack.env ps
}

# Function to backup database
backup() {
    print_status "Creating database backup..."
    BACKUP_FILE="supabase_backup_$(date +%Y%m%d_%H%M%S).sql"

    docker compose --env-file stack.env exec postgres pg_dumpall -U postgres > "$BACKUP_FILE"

    print_success "Backup created: $BACKUP_FILE"
}

# Help function
show_help() {
    echo "Supabase Stack Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  deploy    - Deploy the Supabase stack"
    echo "  stop      - Stop the stack"
    echo "  restart   - Restart the stack"
    echo "  status    - Show stack status"
    echo "  logs      - Show stack logs"
    echo "  backup    - Create database backup"
    echo "  ports     - Show port configuration"
    echo "  ufw       - Show UFW firewall rules"
    echo "  help      - Show this help message"
}

# Main script logic
case "${1:-}" in
    deploy)
        deploy
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    backup)
        backup
        ;;
    ports)
        show_port_info
        ;;
    ufw)
        show_ufw_rules
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [ -z "${1:-}" ]; then
            deploy
        else
            print_error "Unknown command: $1"
            show_help
            exit 1
        fi
        ;;
esac