# Supabase Stack - Port Configuration & UFW Rules

## 📋 Complete Port List

### External Ports (Published to Host - VPN Access Only)
| Service | Internal | External | Protocol | Purpose | UFW Rule |
|---------|----------|----------|----------|---------|----------|
| PostgreSQL 17 | 5432 | 5432 | TCP | Database access for DBeaver/apps | `sudo ufw allow from 172.29.172.0/24 to any port 5432 proto tcp comment 'Supabase PostgreSQL VPN'` |
| Supabase Studio | 3000 | 3000 | TCP | Web UI interface | `sudo ufw allow from 172.29.172.0/24 to any port 3000 proto tcp comment 'Supabase Studio VPN'` |
| Kong API HTTP | 8000 | 8000 | TCP | REST API, Auth, Realtime | `sudo ufw allow from 172.29.172.0/24 to any port 8000 proto tcp comment 'Supabase API HTTP VPN'` |
| Kong API HTTPS | 8443 | 8443 | TCP | SSL/TLS API access | `sudo ufw allow from 172.29.172.0/24 to any port 8443 proto tcp comment 'Supabase API HTTPS VPN'` |
| Analytics (Logflare) | 4000 | 4000 | TCP | Logs and analytics | `sudo ufw allow from 172.29.172.0/24 to any port 4000 proto tcp comment 'Supabase Analytics VPN'` |

### Internal Ports (Docker Network Only)
| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Auth (GoTrue) | 9999 | TCP | Authentication service |
| REST (PostgREST) | 3000 | TCP | Auto-generated REST API |
| Realtime | 4000 | TCP | WebSocket real-time subscriptions |
| Storage API | 5000 | TCP | File upload/download API |
| ImgProxy | 5001 | TCP | Image transformation |
| Meta (pg-meta) | 8080 | TCP | Database metadata for Studio |

## 🔥 UFW Firewall Setup

Run these commands on your Ubuntu server:

```bash
#!/bin/bash
# Supabase UFW Firewall Rules - VPN Access Only

# Allow SSH (if not already configured)
sudo ufw allow 22/tcp comment 'SSH'

# Allow Supabase services from VPN subnet only (172.29.172.0/24)
sudo ufw allow from 172.29.172.0/24 to any port 5432 proto tcp comment 'Supabase PostgreSQL VPN'
sudo ufw allow from 172.29.172.0/24 to any port 3000 proto tcp comment 'Supabase Studio VPN'
sudo ufw allow from 172.29.172.0/24 to any port 8000 proto tcp comment 'Supabase API HTTP VPN'
sudo ufw allow from 172.29.172.0/24 to any port 8443 proto tcp comment 'Supabase API HTTPS VPN'
sudo ufw allow from 172.29.172.0/24 to any port 4000 proto tcp comment 'Supabase Analytics VPN'

# Optional: Allow HTTP/HTTPS for web services (if needed publicly)
# sudo ufw allow 80/tcp comment 'HTTP'
# sudo ufw allow 443/tcp comment 'HTTPS'

# Check UFW status
sudo ufw status numbered

# If UFW is not enabled, enable it
# sudo ufw --force enable
```

## 🔍 Port Conflict Detection

Check for existing services on these ports:

```bash
# Check if ports are in use
echo "Checking Supabase ports for conflicts..."
echo
echo "PostgreSQL (5432):"
sudo netstat -tulpn | grep :5432 || echo "  ✅ Available"
echo
echo "Studio (3000):"
sudo netstat -tulpn | grep :3000 || echo "  ✅ Available"
echo
echo "Kong HTTP (8000):"
sudo netstat -tulpn | grep :8000 || echo "  ✅ Available"
echo
echo "Kong HTTPS (8443):"
sudo netstat -tulpn | grep :8443 || echo "  ✅ Available"
echo
echo "Analytics (4000):"
sudo netstat -tulpn | grep :4000 || echo "  ✅ Available"
```

## 📊 Your n8n Stack Comparison

### Existing n8n Stack (Internal PostgreSQL)
- n8n PostgreSQL: Internal port 5432 (not published) ✅ **No conflict**
- Your n8n stack uses its own Docker network

### Future n8n PostgreSQL Publishing
If you need to publish n8n PostgreSQL later:
- Use port 5433: `"5433:5432"` in n8n docker-compose.yml
- Add VPN-only UFW rule: `sudo ufw allow from 172.29.172.0/24 to any port 5433 proto tcp comment 'n8n PostgreSQL VPN'`

## 🔗 Connection URLs

### External Access URLs (VPN Required)
```bash
# PostgreSQL (DBeaver) - accessible only from VPN clients
postgresql://postgres:password@YOUR-SERVER-IP:5432/supabase

# Supabase Studio (Web UI) - accessible only from VPN clients
http://YOUR-SERVER-IP:3000

# API Gateway - accessible only from VPN clients
http://YOUR-SERVER-IP:8000

# Analytics - accessible only from VPN clients
http://YOUR-SERVER-IP:4000
```

### API Endpoints
```bash
# REST API
http://YOUR-SERVER-IP:8000/rest/v1/

# Authentication
http://YOUR-SERVER-IP:8000/auth/v1/

# Realtime WebSocket
ws://YOUR-SERVER-IP:8000/realtime/v1/

# Storage
http://YOUR-SERVER-IP:8000/storage/v1/
```

## 🎯 Application Integration

### Supabase JavaScript Client
```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://YOUR-SERVER-IP:8000'
const supabaseKey = 'your-anon-key-from-stack-env'
const supabase = createClient(supabaseUrl, supabaseKey)
```

### Direct PostgreSQL Connection (Node.js)
```javascript
const { Pool } = require('pg')

const pool = new Pool({
  user: 'postgres',
  host: 'YOUR-SERVER-IP',
  database: 'supabase',
  password: 'your-password-from-stack-env',
  port: 5432,
})
```

### Python Connection
```python
import psycopg2

conn = psycopg2.connect(
    host="YOUR-SERVER-IP",
    database="supabase",
    user="postgres",
    password="your-password-from-stack-env",
    port="5432"
)
```

## 🛡️ Security Configuration

### VPN-Only Access (172.29.172.0/24)
- All Supabase services are restricted to VPN clients only
- PostgreSQL (5432), Studio (3000), API (8000), HTTPS (8443), Analytics (4000)
- Public internet access is blocked - requires VPN connection

### Additional Security Recommendations
1. **Production Setup**: Use a reverse proxy (Nginx) with SSL certificates
2. **VPN Security**: Ensure VPN clients use strong authentication
3. **Strong Passwords**: Always use generated secrets from `generate-secrets.sh`
4. **Regular Updates**: Keep Docker images updated
5. **Backup Strategy**: Implement automated backups

## 📝 Quick Reference Commands

```bash
# Deploy stack
./deploy.sh

# Check port usage
sudo netstat -tulpn | grep -E "(5432|3000|8000|8443|4000)"

# View stack status
docker-compose --env-file stack.env ps

# Test PostgreSQL connection
docker-compose --env-file stack.env exec postgres pg_isready -U postgres

# Check UFW status
sudo ufw status numbered
```