# Self-Hosted Supabase Stack

## Overview

This directory contains a complete self-hosted Supabase deployment using Docker Compose, including PostgreSQL 17 with pgvector extension for AI/ML applications.

## 📁 Project Structure

```
/home/andy/_projects/AI_Full_Stack_Developer/Hostinger/supabase/
├── docker-compose.yml          # Main orchestration file
├── stack.env                   # Environment configuration
├── kong.yml                    # Kong API Gateway config
├── reset-and-deploy.sh         # Automated deployment script
├── init/                       # Database initialization scripts
│   ├── 00-create-supabase-admin.sql
│   ├── 01-initial-schema.sql
│   ├── 02-auth-schema.sql
│   ├── 03-storage-schema.sql
│   ├── 04-vector-schema.sql
│   └── 05-seed-data.sql
└── docs/                       # Documentation
    ├── DEPLOYMENT.md
    ├── DEPLOYMENT-STATUS.md
    ├── TROUBLESHOOTING.md
    └── API-REFERENCE.md
```

## 🚀 Quick Start

1. **Deploy the stack:**
   ```bash
   ./reset-and-deploy.sh
   ```

2. **Start via Portainer:**
   - Navigate to Portainer UI
   - Deploy the stack using docker-compose.yml

3. **Access services:**
   - Studio: http://172.29.172.1:3000
   - API: http://172.29.172.1:8000
   - Database: 172.29.172.1:5432

## 🔐 Credentials

- **Database Admin:** `supabase_admin` / `HWcns2tWSTXEWRwUGTtsTDfBM9vyCMdn`
- **PostgreSQL User:** `postgres` / `XtrUS1I6ZoBZWlGETTJMJ6Yz6dSPdhm8`

## 📚 Documentation

- [Deployment Guide](./docs/DEPLOYMENT.md) - Complete setup instructions
- [Current Status](./docs/DEPLOYMENT-STATUS.md) - Deployment achievements and current state
- [Troubleshooting](./docs/TROUBLESHOOTING.md) - Common issues and solutions
- [API Reference](./docs/API-REFERENCE.md) - Service endpoints and usage

## 🎯 Current Status: OPERATIONAL ✅

Core services are running and functional:
- ✅ PostgreSQL 17 + pgvector (healthy)
- ✅ Authentication service (44/44 migrations applied)
- ✅ Kong API Gateway (routing correctly)
- ✅ PostgREST API (responding)
- ✅ Storage & Realtime services (operational)
- ✅ Studio UI (accessible)

See [DEPLOYMENT-STATUS.md](./docs/DEPLOYMENT-STATUS.md) for detailed status and achievements.

A complete Supabase deployment with PostgreSQL 17, pgvector extension, and full vector database capabilities for Portainer on Ubuntu.

## 🌟 Features

- **PostgreSQL 17** with pgvector extension for both relational and vector operations
- **Supabase Studio** - Full-featured web UI on port 3000
- **Complete Authentication** - Email, phone, JWT, MFA support
- **File Storage** - With image transformation and CDN-like features
- **Vector Database** - Advanced similarity search with cosine, L2, and inner product
- **Real-time** - WebSocket connections for live updates
- **Analytics** - Built-in logging and analytics with Logflare
- **Row Level Security** - Database-level access control
- **API Gateway** - Kong for secure API access

## 🗂️ Directory Structure

```
supabase/
├── docker-compose.yml          # Main Docker Compose configuration
├── stack.env                   # Environment variables
├── deploy.sh                   # Deployment and management script
├── init/                       # Database initialization scripts
│   ├── 01-initial-schema.sql   # Basic schemas and extensions
│   ├── 02-auth-schema.sql      # Extended authentication schema
│   ├── 03-storage-schema.sql   # File storage schema
│   ├── 04-vector-schema.sql    # Vector operations schema
│   └── 05-seed-data.sql        # Sample data and relational tables
├── scripts/                    # Helper scripts
│   ├── generate-secrets.sh     # Generate secure passwords and JWT tokens
│   └── backup.sh              # Database backup and restore
└── volumes/                    # Docker volumes
    ├── api/kong.yml           # Kong API gateway configuration
    └── storage/               # File storage directory
```

## 🚀 Quick Start

### 1. Configure Environment Variables

Edit `stack.env` and update these key values:

```bash
# Replace with your server's IP address
API_EXTERNAL_URL=http://YOUR-SERVER-IP:8000
PUBLIC_REST_URL=http://YOUR-SERVER-IP:8000/rest/v1/
SITE_URL=http://YOUR-SERVER-IP:3000

# Configure SMTP for email authentication
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 2. Generate Secure Secrets

```bash
# Generate new passwords and JWT tokens
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh
```

### 3. Deploy the Stack

```bash
# Make deployment script executable
chmod +x deploy.sh

# Deploy (includes UFW firewall rules and connection info)
./deploy.sh
```

## 🔌 Port Configuration

| Service | Internal Port | External Port | Purpose |
|---------|--------------|---------------|---------|
| PostgreSQL | 5432 | 5432 | Database access (DBeaver) |
| Supabase Studio | 3000 | 3000 | Web UI |
| Kong HTTP | 8000 | 8000 | API Gateway |
| Kong HTTPS | 8443 | 8443 | API Gateway SSL |
| Analytics | 4000 | 4000 | Logflare/Analytics |

## 🔐 UFW Firewall Rules

Run these commands on your Ubuntu server:

```bash
# Allow PostgreSQL (for DBeaver)
sudo ufw allow 5432/tcp comment 'Supabase PostgreSQL'

# Allow Supabase Studio
sudo ufw allow 3000/tcp comment 'Supabase Studio'

# Allow API Gateway
sudo ufw allow 8000/tcp comment 'Supabase API HTTP'
sudo ufw allow 8443/tcp comment 'Supabase API HTTPS'

# Allow Analytics
sudo ufw allow 4000/tcp comment 'Supabase Analytics'

# Check status
sudo ufw status numbered
```

## 🗄️ Database Schemas

### Public Schema (`public`)
Your main relational database tables:
- `users_profile` - Extended user profiles
- `projects` - User projects with settings
- `documents` - Document metadata (pairs with vector embeddings)
- `analytics_events` - Event tracking and analytics

### Vectors Schema (`vectors`)
AI/ML vector operations:
- `embeddings` - Vector embeddings with metadata
- `collections` - Organize embeddings by project/use case

### Auth Schema (`auth`)
Supabase authentication:
- `users` - User accounts
- `sessions` - User sessions
- `refresh_tokens` - JWT refresh tokens
- `identities` - OAuth identities
- MFA tables for multi-factor authentication

### Storage Schema (`storage`)
File storage:
- `buckets` - Storage buckets
- `objects` - File metadata

## 🎯 Vector Database Usage

### Insert Embeddings

```sql
-- Insert a document with embedding
INSERT INTO vectors.embeddings (content, embedding, metadata, collection_name, owner_id)
VALUES (
    'Your document content here',
    '[0.1, 0.2, 0.3, ...]'::vector, -- Your embedding vector
    '{"category": "documentation", "tags": ["api", "guide"]}',
    'documents',
    auth.uid()
);
```

### Search by Similarity

```sql
-- Cosine similarity search
SELECT * FROM vectors.search_embeddings_cosine(
    '[0.1, 0.2, 0.3, ...]'::vector(1536), -- Query embedding
    10, -- Number of results
    'documents', -- Collection filter (optional)
    '{"category": "documentation"}' -- Metadata filter (optional)
);

-- L2 distance search
SELECT * FROM vectors.search_embeddings_l2(
    '[0.1, 0.2, 0.3, ...]'::vector(1536),
    5
);

-- Inner product search
SELECT * FROM vectors.search_embeddings_inner_product(
    '[0.1, 0.2, 0.3, ...]'::vector(1536),
    5
);
```

### Collection Management

```sql
-- Create a new collection
INSERT INTO vectors.collections (name, description, embedding_model)
VALUES ('my_docs', 'My document embeddings', 'text-embedding-ada-002');

-- Get collection statistics
SELECT * FROM vectors.get_collection_stats('my_docs');
```

## 💾 Database Backup & Restore

```bash
# Make backup script executable
chmod +x scripts/backup.sh

# Create full backup
./scripts/backup.sh full

# Create schema-only backup
./scripts/backup.sh schema

# Create vectors schema backup
./scripts/backup.sh vectors

# List available backups
./scripts/backup.sh list

# Restore from backup
./scripts/backup.sh restore backups/supabase_full_backup_20241111_120000.sql.gz

# Clean up old backups (30+ days)
./scripts/backup.sh cleanup
```

## 🔗 Connection Examples

### DBeaver Connection

```
Host: your-server-ip
Port: 5432
Database: supabase
Username: postgres
Password: (from stack.env)
```

### Application Connection String

```
postgresql://postgres:password@your-server-ip:5432/supabase
```

### Supabase Client Configuration

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://your-server-ip:8000'
const supabaseKey = 'your-anon-key-from-stack-env'

const supabase = createClient(supabaseUrl, supabaseKey)
```

## 📊 Management Commands

### Using deploy.sh

```bash
# Deploy the stack
./deploy.sh

# Stop the stack
./deploy.sh stop

# Restart the stack
./deploy.sh restart

# View logs
./deploy.sh logs

# Show status
./deploy.sh status

# Show port configuration
./deploy.sh ports

# Show UFW rules
./deploy.sh ufw
```

### Direct Docker Compose

```bash
# Start services
docker-compose --env-file stack.env up -d

# Stop services
docker-compose --env-file stack.env down

# View logs
docker-compose --env-file stack.env logs -f

# Restart specific service
docker-compose --env-file stack.env restart postgres
```

## 🔧 Troubleshooting

### Check Service Health

```bash
# View all services
docker-compose --env-file stack.env ps

# Check PostgreSQL
docker-compose --env-file stack.env exec postgres pg_isready -U postgres

# View service logs
docker-compose --env-file stack.env logs postgres
docker-compose --env-file stack.env logs studio
```

### Common Issues

1. **Port conflicts**: Check if ports are already in use
   ```bash
   sudo netstat -tulpn | grep :5432
   ```

2. **Permission issues**: Ensure storage directory is writable
   ```bash
   sudo chown -R 1000:1000 volumes/storage
   ```

3. **Memory issues**: Adjust PostgreSQL memory limits in `stack.env`

## 🔒 Security Notes

1. **Change default passwords**: Always run `generate-secrets.sh` before deployment
2. **Configure SMTP**: Set up proper email authentication
3. **Update server IP**: Replace all `your-server-ip` placeholders in `stack.env`
4. **Enable UFW**: Configure firewall rules as shown above
5. **Row Level Security**: All tables have RLS enabled by default
6. **Regular backups**: Set up automated backups using the backup script

## 🎨 Supabase Studio Features

Access Supabase Studio at `http://your-server-ip:3000`:

- **Database**: Browse tables, run SQL queries, manage schemas
- **Auth**: Manage users, configure providers, set policies
- **Storage**: Upload files, manage buckets, set permissions
- **Edge Functions**: Deploy serverless functions
- **API**: View auto-generated REST APIs
- **Logs**: Monitor database and application logs

## 🚀 Production Considerations

1. **SSL**: Configure Kong for HTTPS in production
2. **Domain**: Set up proper domain names instead of IP addresses
3. **Monitoring**: Consider adding monitoring stack (Prometheus + Grafana)
4. **Scaling**: Adjust resource limits based on usage
5. **Backups**: Set up automated daily backups
6. **Security**: Regular security updates and patches

---

For support or questions, check the [Supabase documentation](https://supabase.com/docs) or open an issue in this repository.