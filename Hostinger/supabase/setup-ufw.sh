#!/bin/bash

# Supabase UFW Firewall Setup Script
# Configures VPN-only access (172.29.172.0/24) for all Supabase services

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

# Check if running with sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        print_error "This script requires sudo privileges to configure UFW"
        print_error "Please run with sudo or ensure your user has sudo access"
        exit 1
    fi
    print_success "Sudo access confirmed"
}

# Check if UFW is installed
check_ufw_installed() {
    if ! command -v ufw &> /dev/null; then
        print_error "UFW is not installed. Installing UFW..."
        sudo apt update
        sudo apt install ufw -y
        print_success "UFW installed successfully"
    else
        print_success "UFW is already installed"
    fi
}

# Show current UFW status
show_current_status() {
    print_status "Current UFW status:"
    sudo ufw status numbered
    echo
}

# Backup current UFW rules
backup_ufw_rules() {
    BACKUP_DIR="/tmp/ufw_backup_$(date +%Y%m%d_%H%M%S)"
    print_status "Creating UFW rules backup in: $BACKUP_DIR"

    sudo mkdir -p "$BACKUP_DIR"

    # Backup UFW rules if they exist
    if [ -d "/etc/ufw" ]; then
        sudo cp -r /etc/ufw "$BACKUP_DIR/"
        print_success "UFW rules backed up to: $BACKUP_DIR"
    else
        print_warning "No existing UFW configuration found to backup"
    fi
}

# Check if SSH rule already exists
check_ssh_rule() {
    if sudo ufw status | grep -q "22/tcp\|22 \|OpenSSH\|ssh"; then
        print_success "✅ SSH access rule already exists - skipping"
        return 0
    else
        return 1
    fi
}

# Check if a specific port rule already exists
check_port_rule() {
    local port=$1
    local description=$2

    if sudo ufw status | grep -q "${port}/tcp\|${port} "; then
        print_warning "⚠️  Rule for port ${port} already exists - skipping ${description}"
        return 0
    else
        return 1
    fi
}

# Add UFW rule with duplicate check
add_ufw_rule() {
    local rule=$1
    local port=$2
    local description=$3
    local success_msg=$4

    if ! check_port_rule "$port" "$description"; then
        print_status "Adding rule for ${description}..."
        eval "sudo ufw $rule"
        print_success "$success_msg"
    fi
}

# Configure Supabase UFW rules
configure_supabase_rules() {
    print_status "Configuring Supabase UFW rules for VPN-only access (172.29.172.0/24)..."
    echo

    # Allow SSH (if not already configured) - IMPORTANT: Keep SSH access!
    print_status "Checking SSH access configuration..."
    if ! check_ssh_rule; then
        print_status "Adding SSH access rule..."
        sudo ufw allow ssh comment 'SSH access'
        print_success "✅ SSH access rule added"
    fi

    # Allow Supabase services from VPN subnet only
    print_status "Adding Supabase service rules..."
    echo

    # PostgreSQL (Database access for DBeaver, applications)
    add_ufw_rule "allow from 172.29.172.0/24 to any port 5432 proto tcp comment 'Supabase PostgreSQL VPN'" "5432" "PostgreSQL" "✅ PostgreSQL (5432) - VPN access configured"

    # Supabase Studio (Web UI)
    add_ufw_rule "allow from 172.29.172.0/24 to any port 3000 proto tcp comment 'Supabase Studio VPN'" "3000" "Supabase Studio" "✅ Supabase Studio (3000) - VPN access configured"

    # Kong API Gateway HTTP
    add_ufw_rule "allow from 172.29.172.0/24 to any port 8000 proto tcp comment 'Supabase API HTTP VPN'" "8000" "Kong API HTTP" "✅ Kong API HTTP (8000) - VPN access configured"

    # Kong API Gateway HTTPS
    # add_ufw_rule "allow from 172.29.172.0/24 to any port 8443 proto tcp comment 'Supabase API HTTPS VPN'" "8443" "Kong API HTTPS" "✅ Kong API HTTPS (8443) - VPN access configured"

    # Analytics (Logflare)
    add_ufw_rule "allow from 172.29.172.0/24 to any port 4000 proto tcp comment 'Supabase Analytics VPN'" "4000" "Analytics (Logflare)" "✅ Analytics (4000) - VPN access configured"

    echo
    print_success "All Supabase UFW rules configured successfully!"
}

# Optional: Configure additional common rules
configure_optional_rules() {
    read -p "Do you want to allow HTTP/HTTPS for web services? (y/N): " allow_web
    if [[ $allow_web =~ ^[Yy]$ ]]; then
        add_ufw_rule "allow 80/tcp comment 'HTTP'" "80" "HTTP" "✅ HTTP (80) access configured"
        add_ufw_rule "allow 443/tcp comment 'HTTPS'" "443" "HTTPS" "✅ HTTPS (443) access configured"
    fi

    read -p "Do you want to allow Docker API access from VPN? (y/N): " allow_docker
    if [[ $allow_docker =~ ^[Yy]$ ]]; then
        add_ufw_rule "allow from 172.29.172.0/24 to any port 2376 proto tcp comment 'Docker API VPN'" "2376" "Docker API" "✅ Docker API (2376) - VPN access configured"
    fi

    read -p "Do you want to allow Portainer access from VPN? (y/N): " allow_portainer
    if [[ $allow_portainer =~ ^[Yy]$ ]]; then
        add_ufw_rule "allow from 172.29.172.0/24 to any port 9000 proto tcp comment 'Portainer Web VPN'" "9000" "Portainer Web" "✅ Portainer Web (9000) - VPN access configured"
        add_ufw_rule "allow from 172.29.172.0/24 to any port 9443 proto tcp comment 'Portainer HTTPS VPN'" "9443" "Portainer HTTPS" "✅ Portainer HTTPS (9443) - VPN access configured"
    fi
}

# Enable UFW if not already enabled
enable_ufw() {
    if sudo ufw status | grep -q "Status: inactive"; then
        print_warning "UFW is currently inactive"
        read -p "Do you want to enable UFW now? (y/N): " enable_now
        if [[ $enable_now =~ ^[Yy]$ ]]; then
            print_status "Enabling UFW..."
            sudo ufw --force enable
            print_success "✅ UFW enabled successfully"
        else
            print_warning "UFW not enabled. Remember to enable it manually with: sudo ufw enable"
        fi
    else
        print_success "✅ UFW is already enabled"
    fi
}

# Show final UFW configuration
show_final_status() {
    echo
    print_status "Final UFW configuration:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│                    UFW Rules Summary                        │"
    echo "└─────────────────────────────────────────────────────────────┘"
    sudo ufw status numbered
    echo

    print_status "Supabase services are now accessible only via VPN:"
    echo "🌐 Supabase Studio:  http://172.29.172.1:3000"
    echo "🔗 API Gateway:      http://172.29.172.1:8000"
    echo "🗄️  PostgreSQL:      172.29.172.1:5432 (DBeaver)"
    echo "📊 Analytics:        http://172.29.172.1:4000"
    echo
    print_success "✅ VPN-only access configuration complete!"
}

# Show help information
show_help() {
    echo "Supabase UFW Setup Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  setup     - Full UFW setup for Supabase (default)"
    echo "  status    - Show current UFW status"
    echo "  reset     - Reset UFW rules (WARNING: Removes all rules)"
    echo "  backup    - Create backup of current UFW rules"
    echo "  help      - Show this help message"
    echo
    echo "This script configures UFW to allow Supabase services only from VPN subnet 172.29.172.0/24"
}

# Reset UFW rules (dangerous operation)
reset_ufw() {
    print_warning "⚠️  WARNING: This will remove ALL UFW rules!"
    print_warning "⚠️  You may lose SSH access if not properly configured!"
    echo
    read -p "Are you absolutely sure you want to reset UFW? Type 'RESET' to confirm: " confirm

    if [ "$confirm" = "RESET" ]; then
        print_status "Resetting UFW rules..."
        sudo ufw --force reset
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        print_success "UFW rules reset. Please reconfigure access rules immediately!"
        print_warning "⚠️  Don't forget to allow SSH: sudo ufw allow ssh"
    else
        print_status "Reset cancelled"
    fi
}

# Main setup function
setup_ufw() {
    print_status "🔥 Starting Supabase UFW Setup..."
    echo "========================================"
    echo

    check_sudo
    check_ufw_installed
    show_current_status
    backup_ufw_rules

    # Ask for confirmation
    read -p "Continue with Supabase UFW configuration? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled"
        exit 0
    fi

    configure_supabase_rules
    # configure_optional_rules
    enable_ufw
    show_final_status
}

# Main script logic
case "${1:-setup}" in
    setup)
        setup_ufw
        ;;
    status)
        show_current_status
        ;;
    reset)
        reset_ufw
        ;;
    backup)
        check_sudo
        backup_ufw_rules
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac