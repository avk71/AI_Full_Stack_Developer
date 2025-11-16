#!/bin/bash
# pre-pull-images.sh - Pre-pull all Supabase images for Portainer deployment
# This avoids rate limiting by caching images locally before Portainer deployment

set -e

echo "🔄 Pre-pulling all Supabase images..."
echo "====================================="

# Load environment variables
if [ -f "stack.env" ]; then
    export $(grep -v '^#' stack.env | xargs)
    echo "📋 Loaded environment from stack.env"
else
    echo "⚠️  stack.env not found, using defaults"
fi

# List of all images from docker-compose.yml
images=(
    "pgvector/pgvector:pg17"
    "supabase/studio:latest"
    "kong:2.8.1"
    "supabase/gotrue:v2.143.0"
    "postgrest/postgrest:v12.2.0"
    "supabase/realtime:v2.27.5"
    "supabase/storage-api:latest"
    "darthsim/imgproxy:v3.8.0"
    "supabase/postgres-meta:v0.80.0"
    "supabase/logflare:1.4.0"
    "supabase/edge-runtime:v1.45.2"
)

echo "📥 Pulling ${#images[@]} images..."
echo ""

# Track success/failure
pulled=0
failed=0

for image in "${images[@]}"; do
    echo "🔄 Pulling $image..."
    if docker pull "$image"; then
        echo "✅ $image pulled successfully"
        pulled=$((pulled + 1))
    else
        echo "❌ Failed to pull $image"
        failed=$((failed + 1))
    fi
    echo ""
done

echo "====================================="
echo "📊 Pre-pull Summary:"
echo "   ✅ Successfully pulled: $pulled images"
echo "   ❌ Failed: $failed images"
echo ""

if [ $failed -eq 0 ]; then
    echo "🎉 All images cached! Portainer deployment should work without rate limits."
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Deploy the stack in Portainer"
    echo "   2. Images will be loaded from local cache"
    echo "   3. No Docker Hub API calls needed during deployment"
else
    echo "⚠️  Some images failed to pull. Portainer deployment might still work"
    echo "   if these images are cached from previous runs."
fi

echo ""
echo "🐳 Local Docker image cache:"
docker images | grep -E "(supabase|pgvector|kong|postgrest|darthsim|logflare)" | head -20