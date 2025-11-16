#!/bin/bash

# Supabase Docker Image Verification Script
# Checks if all required Docker images are available

echo "🔍 Checking Supabase Docker images availability..."
echo "================================================="

# List of images to check
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

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

failed_images=()
success_count=0

for image in "${images[@]}"; do
    echo -n "Checking $image... "

    if docker manifest inspect "$image" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Available${NC}"
        ((success_count++))
    else
        echo -e "${RED}❌ Not found${NC}"
        failed_images+=("$image")
    fi
done

echo
echo "================================================="
echo "Results: $success_count/${#images[@]} images available"

if [ ${#failed_images[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All images are available! Ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ The following images are not available:${NC}"
    for image in "${failed_images[@]}"; do
        echo "  - $image"
    done
    echo
    echo -e "${YELLOW}💡 Suggestions:${NC}"
    echo "1. Check if these are the latest available versions"
    echo "2. Try using 'latest' tag for problematic images"
    echo "3. Check Docker Hub for correct image tags"
    exit 1
fi