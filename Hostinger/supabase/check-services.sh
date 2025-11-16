#!/bin/bash
# check-services.sh - Monitor Supabase services status

echo "🔍 Checking Supabase Services Status..."
echo "======================================"

VPN_IP="172.29.172.1"

echo "📊 Service Accessibility Check:"
echo ""

# PostgreSQL
echo "🐘 PostgreSQL (Port 5432):"
if nc -z $VPN_IP 5432 2>/dev/null; then
    echo "  ✅ Database accessible"
else
    echo "  ❌ Database not responding"
fi

# Studio
echo ""
echo "🎨 Supabase Studio (Port 3000):"
if nc -z $VPN_IP 3000 2>/dev/null; then
    echo "  ✅ Studio port open"
    if curl -s -I http://$VPN_IP:3000 2>/dev/null | head -1 | grep -q "200\|307\|302"; then
        echo "  ✅ Studio responding (HTTP redirect is normal)"
    else
        echo "  ⏳ Studio port open but not fully ready yet"
    fi
else
    echo "  ⏳ Studio still starting..."
fi

# Kong API Gateway
echo ""
echo "🦍 Kong API Gateway (Port 8000):"
if nc -z $VPN_IP 8000 2>/dev/null; then
    echo "  ✅ Kong port open"
    if curl -s -I http://$VIP_IP:8000 2>/dev/null | head -1 | grep -q "404\|200"; then
        echo "  ✅ Kong API Gateway responding"
    else
        echo "  ⏳ Kong port open but configuring..."
    fi
else
    echo "  ❌ Kong not responding"
fi

# Analytics
echo ""
echo "📊 Analytics (Port 4000):"
if nc -z $VIP_IP 4000 2>/dev/null; then
    echo "  ✅ Analytics accessible"
else
    echo "  ⏳ Analytics starting..."
fi

echo ""
echo "🔗 Quick Access URLs (via VPN):"
echo "   📊 Supabase Studio: http://$VPN_IP:3000"
echo "   🔌 API Gateway:     http://$VPN_IP:8000"
echo "   📈 Analytics:       http://$VPN_IP:4000"
echo "   🐘 PostgreSQL:      $VPN_IP:5432"
echo ""
echo "⏰ Note: Studio (Next.js app) can take 2-3 minutes to fully start"
echo "   The container may show as 'running' while the app is still building"