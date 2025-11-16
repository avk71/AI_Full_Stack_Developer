#!/bin/bash
# setup-kong-config.sh - Copy Kong configuration to persistent volume

set -e

echo "🔧 Setting up Kong configuration..."

# Create the directory if it doesn't exist
sudo mkdir -p /opt/stacks/apps/database/supabase/kong_config

# Copy the kong.yml file
sudo cp kong.yml /opt/stacks/apps/database/supabase/kong_config/

# Set proper ownership
sudo chown -R $USER:$USER /opt/stacks/apps/database/supabase/kong_config/

# Verify the file is there
if [ -f "/opt/stacks/apps/database/supabase/kong_config/kong.yml" ]; then
    echo "✅ Kong configuration copied successfully!"
    echo "📁 Location: /opt/stacks/apps/database/supabase/kong_config/kong.yml"
    ls -la /opt/stacks/apps/database/supabase/kong_config/
else
    echo "❌ Failed to copy Kong configuration"
    exit 1
fi

echo ""
echo "🔄 Next steps:"
echo "   1. Restart Kong container: docker-compose restart kong"
echo "   2. Or redeploy the stack in Portainer"