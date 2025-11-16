#!/bin/bash

# Setup local-persist Docker plugin for Supabase
# This script installs and configures the local-persist plugin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root or with sudo access
check_permissions() {
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        print_error "This script requires sudo access to create directories in /opt/"
        print_error "Please run with sudo or ensure your user has sudo privileges"
        exit 1
    fi
    print_success "Sufficient permissions confirmed"
}

# Install local-persist plugin
install_plugin() {
    print_status "Checking for local-persist plugin..."

    if docker plugin ls | grep -q local-persist; then
        print_warning "local-persist plugin is already installed"
        return 0
    fi

    print_status "Installing local-persist Docker plugin..."

    # Install the plugin
    docker plugin install cwspear/docker-local-persist-volume-plugin:latest

    # Enable the plugin
    docker plugin enable cwspear/docker-local-persist-volume-plugin:latest

    print_success "local-persist plugin installed and enabled"
}

# Create base directory structure
create_base_structure() {
    print_status "Creating base directory structure..."

    # Create the base directory for all persistent volumes
    sudo mkdir -p /opt/stacks/apps/database

    # Set proper ownership
    sudo chown -R $(id -u):$(id -g) /opt/stacks/apps/

    # Set proper permissions
    sudo chmod -R 755 /opt/stacks/apps/

    print_success "Base directory structure created: /opt/stacks/apps/database"
}

# Verify plugin installation
verify_installation() {
    print_status "Verifying plugin installation..."

    if docker plugin ls | grep -q "local-persist.*true"; then
        print_success "✅ local-persist plugin is installed and enabled"
    else
        print_error "❌ Plugin installation failed or not enabled"
        exit 1
    fi

    if [ -d "/opt/stacks/apps/database" ]; then
        print_success "✅ Base directory structure exists"
    else
        print_error "❌ Base directory creation failed"
        exit 1
    fi
}

# Show usage information
show_info() {
    print_status "Setup completed! You can now deploy Supabase with persistent volumes."
    echo
    echo "📁 Volume Storage Location: /opt/stacks/apps/database/supabase/"
    echo "🔧 Plugin: cwspear/docker-local-persist-volume-plugin"
    echo "📝 Next Step: Run ./deploy.sh to deploy Supabase"
    echo
    print_warning "Note: All volume data will be stored in /opt/stacks/apps/database/supabase/"
    print_warning "Make sure to include this directory in your backup strategy!"
}

# Main execution
main() {
    echo "🐳 Supabase Local-Persist Setup Script"
    echo "======================================="
    echo

    check_permissions
    install_plugin
    create_base_structure
    verify_installation
    show_info
}

# Run main function
main