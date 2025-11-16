#!/bin/bash
# verify-images.sh - Verify Docker images availability using Docker Hub API
# This script checks if all images used in docker-compose.yml are available

echo "🔍 Verifying Docker images availability..."
echo "=========================================="

# Extract images from docker-compose.yml (excluding commented lines)
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

# Function to check image availability via Docker Hub API
check_image() {
    local image="$1"
    local repo
    local tag

    # Split image into repo and tag
    if [[ "$image" == *":"* ]]; then
        repo="${image%:*}"
        tag="${image##*:}"
    else
        repo="$image"
        tag="latest"
    fi

    # Handle library images (no namespace)
    if [[ "$repo" != *"/"* ]]; then
        repo="library/$repo"
    fi

    # Check via Docker Hub API
    local url="https://hub.docker.com/v2/repositories/$repo/tags/$tag/"
    local response
    response=$(curl -s "$url")

    if echo "$response" | grep -q '"name"'; then
        echo "✅ $image - Available"
        return 0
    else
        echo "❌ $image - Not found"
        return 1
    fi
}

# Check all images
failed=0
total=${#images[@]}
echo "Checking $total images..."
echo ""

for image in "${images[@]}"; do
    if ! check_image "$image"; then
        failed=$((failed + 1))
    fi
done

echo ""
echo "=========================================="
echo "Summary: $((total - failed))/$total images available"

if [ $failed -eq 0 ]; then
    echo "🎉 All images are available! Ready for deployment."
    exit 0
else
    echo "⚠️  $failed image(s) not found. Check image names and versions."
    exit 1
fi