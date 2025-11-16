#!/bin/bash
# debug-studio.sh - Troubleshoot Supabase Studio issues

echo "🔍 Diagnosing Supabase Studio Issues..."
echo "====================================="

# Check if we're in the right directory
cd /home/andy/_projects/AI_Full_Stack_Developer/Hostinger/supabase

# Check container status
echo "📊 Container Status:"
docker-compose ps studio meta postgres kong

echo ""
echo "📋 Studio Container Logs (last 20 lines):"
docker-compose logs --tail=20 studio

echo ""
echo "🔗 Dependency Check:"
echo "- PostgreSQL:"
docker-compose exec postgres pg_isready -U postgres -d supabase 2>/dev/null && echo "  ✅ PostgreSQL is ready" || echo "  ❌ PostgreSQL not ready"

echo "- Meta service:"
curl -s http://172.29.172.1:8080/health 2>/dev/null && echo "  ✅ Meta service is healthy" || echo "  ❌ Meta service not responding"

echo "- Kong API Gateway:"
curl -s -I http://172.29.172.1:8000 2>/dev/null | head -1 && echo "  ✅ Kong is responding" || echo "  ❌ Kong not responding"

echo ""
echo "🌐 Studio Access Test:"
curl -s -I http://172.29.172.1:3000 2>/dev/null | head -1 && echo "  ✅ Studio is responding" || echo "  ❌ Studio not responding"

echo ""
echo "🔧 Quick Fixes to Try:"
echo "1. Restart Studio container:"
echo "   docker-compose restart studio"
echo ""
echo "2. Check environment variables:"
echo "   docker-compose exec studio printenv | grep -E 'STUDIO|SUPABASE|POSTGRES'"
echo ""
echo "3. Full stack restart:"
echo "   docker-compose down && docker-compose up -d"