#!/bin/bash
# =============================================
# Generate Secure Secrets for Supabase Stack
# =============================================

set -e

echo "🔐 Generating secure secrets for Supabase stack..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate a random string
generate_secret() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate JWT
generate_jwt() {
    local role=$1
    local secret=$2

    # JWT Header (base64url encoded)
    header=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 -w 0 | tr -d '=' | tr '/+' '_-')

    # JWT Payload (base64url encoded)
    if [ "$role" = "anon" ]; then
        payload=$(echo -n "{\"iss\":\"supabase\",\"role\":\"anon\",\"exp\":1983812996}" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
    else
        payload=$(echo -n "{\"iss\":\"supabase\",\"role\":\"service_role\",\"exp\":1983812996}" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
    fi

    # Create signature
    signature=$(echo -n "$header.$payload" | openssl dgst -sha256 -hmac "$secret" -binary | base64 -w 0 | tr -d '=' | tr '/+' '_-')

    echo "$header.$payload.$signature"
}

# Check if stack.env exists
if [ ! -f "stack.env" ]; then
    echo -e "${RED}❌ stack.env file not found!${NC}"
    echo "Please run this script from the supabase directory."
    exit 1
fi

# Create backup
echo -e "${BLUE}📋 Creating backup of existing stack.env...${NC}"
cp stack.env stack.env.backup.$(date +%Y%m%d_%H%M%S)

# Generate new secrets
echo -e "${BLUE}🔑 Generating new secrets...${NC}"

POSTGRES_PASSWORD=$(generate_secret 32)
JWT_SECRET=$(generate_secret 64)
LOGFLARE_API_KEY=$(generate_secret 32)

# Generate JWTs with new secret
ANON_KEY=$(generate_jwt "anon" "$JWT_SECRET")
SERVICE_ROLE_KEY=$(generate_jwt "service_role" "$JWT_SECRET")

echo -e "${YELLOW}🔄 Updating stack.env file...${NC}"

# Use a safer approach with awk to avoid sed delimiter issues
# Create temporary file with updated values
awk -v postgres_pwd="$POSTGRES_PASSWORD" \
    -v jwt_secret="$JWT_SECRET" \
    -v logflare_key="$LOGFLARE_API_KEY" \
    -v anon_key="$ANON_KEY" \
    -v service_key="$SERVICE_ROLE_KEY" '
BEGIN { FS="="; OFS="=" }
/^POSTGRES_PASSWORD=/ { $2=postgres_pwd }
/^JWT_SECRET=/ { $2=jwt_secret }
/^LOGFLARE_API_KEY=/ { $2=logflare_key }
/^ANON_KEY=/ { $2=anon_key }
/^SERVICE_ROLE_KEY=/ { $2=service_key }
{ print }
' stack.env > stack.env.tmp && mv stack.env.tmp stack.env

echo ""
echo -e "${GREEN}✅ Secrets generated successfully!${NC}"
echo ""
echo -e "${BLUE}📝 New secrets generated:${NC}"
echo -e "  • PostgreSQL Password: ${GREEN}[32 chars]${NC}"
echo -e "  • JWT Secret: ${GREEN}[64 chars]${NC}"
echo -e "  • Logflare API Key: ${GREEN}[32 chars]${NC}"
echo -e "  • Anonymous JWT Key: ${GREEN}[generated]${NC}"
echo -e "  • Service Role JWT Key: ${GREEN}[generated]${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo -e "  1. Update your-server-ip in stack.env to your actual server IP"
echo -e "  2. Configure SMTP settings if you need email authentication"
echo -e "  3. Backup created: stack.env.backup.$(date +%Y%m%d_%H%M%S)"
echo ""
echo -e "${BLUE}🚀 Ready to deploy with: docker-compose --env-file stack.env up -d${NC}"