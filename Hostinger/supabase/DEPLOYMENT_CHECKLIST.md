# 🚀 Supabase Stack Deployment Checklist

## ✅ Pre-Deployment Checklist

### 1. Environment Configuration
- [ ] Update `API_EXTERNAL_URL` in `stack.env` to your server IP
- [ ] Update `PUBLIC_REST_URL` in `stack.env` to your server IP
- [ ] Update `SITE_URL` in `stack.env` to your server IP
- [ ] Configure SMTP settings if you need email authentication
- [ ] Run `./scripts/generate-secrets.sh` to generate secure passwords

### 2. Port Availability Check
- [ ] Port 5432 (PostgreSQL) - for DBeaver connections
- [ ] Port 3000 (Supabase Studio) - web UI
- [ ] Port 8000 (API Gateway) - REST APIs
- [ ] Port 8443 (API Gateway HTTPS) - SSL APIs
- [ ] Port 4000 (Analytics) - logging

Run: `sudo netstat -tulpn | grep -E "(5432|3000|8000|8443|4000)"`

### 3. System Requirements
- [ ] Docker and Docker Compose installed
- [ ] At least 4GB RAM available
- [ ] At least 10GB disk space
- [ ] UFW firewall configured (optional but recommended)

## 🚀 Deployment Steps

### Step 1: Generate Secrets
```bash
cd /path/to/supabase
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh
```

### Step 2: Update Environment Variables
Edit `stack.env` file:
```bash
# Replace YOUR-SERVER-IP with actual IP
nano stack.env
```

### Step 3: Deploy Stack
```bash
chmod +x deploy.sh
./deploy.sh
```

### Step 4: Configure Firewall
```bash
sudo ufw allow 5432/tcp comment 'Supabase PostgreSQL'
sudo ufw allow 3000/tcp comment 'Supabase Studio'
sudo ufw allow 8000/tcp comment 'Supabase API HTTP'
sudo ufw allow 8443/tcp comment 'Supabase API HTTPS'
sudo ufw allow 4000/tcp comment 'Supabase Analytics'
```

### Step 5: Verify Deployment
- [ ] Check all services are running: `docker-compose --env-file stack.env ps`
- [ ] Test PostgreSQL: `docker-compose --env-file stack.env exec postgres pg_isready -U postgres`
- [ ] Open Supabase Studio: `http://YOUR-SERVER-IP:3000`
- [ ] Test API: `curl http://YOUR-SERVER-IP:8000/rest/v1/`

## 📋 Post-Deployment Verification

### Database Access
- [ ] **DBeaver Connection**:
  - Host: YOUR-SERVER-IP
  - Port: 5432
  - Database: supabase
  - Username: postgres
  - Password: (from stack.env)

### Web Interfaces
- [ ] **Supabase Studio**: http://YOUR-SERVER-IP:3000
- [ ] **Analytics**: http://YOUR-SERVER-IP:4000

### API Endpoints
- [ ] **REST API**: http://YOUR-SERVER-IP:8000/rest/v1/
- [ ] **Auth API**: http://YOUR-SERVER-IP:8000/auth/v1/
- [ ] **Storage API**: http://YOUR-SERVER-IP:8000/storage/v1/

### Vector Database Testing
Test vector operations in SQL:
```sql
-- In DBeaver or Supabase Studio SQL Editor:

-- 1. Check vector extension
SELECT extname FROM pg_extension WHERE extname = 'vector';

-- 2. Check schemas
SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('vectors', 'auth', 'storage', 'public');

-- 3. Test vector tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'vectors';

-- 4. Check sample collections
SELECT * FROM vectors.collections;
```

## 🔧 Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check logs
docker-compose --env-file stack.env logs

# Check specific service
docker-compose --env-file stack.env logs postgres
```

#### Port Already in Use
```bash
# Find what's using the port
sudo netstat -tulpn | grep :5432

# Stop conflicting service or change port
```

#### Permission Denied
```bash
# Fix storage permissions
sudo chown -R 1000:1000 volumes/
```

#### Connection Refused
- [ ] Check if UFW is blocking ports
- [ ] Verify services are running
- [ ] Check Docker network configuration

### Health Checks
```bash
# All services status
docker-compose --env-file stack.env ps

# PostgreSQL health
docker-compose --env-file stack.env exec postgres pg_isready -U postgres

# Studio accessibility
curl -I http://YOUR-SERVER-IP:3000

# API accessibility
curl -I http://YOUR-SERVER-IP:8000/rest/v1/
```

## 🎯 Next Steps After Deployment

### 1. Create Your First User
- Open Supabase Studio: http://YOUR-SERVER-IP:3000
- Go to Authentication > Users
- Create a new user or enable email signup

### 2. Set Up Your First Project
- Create tables in the `public` schema
- Set up Row Level Security policies
- Create your first vector collection

### 3. Test Vector Operations
```sql
-- Create a collection
INSERT INTO vectors.collections (name, description)
VALUES ('test_docs', 'Test document collection');

-- Insert an embedding (replace with real embedding)
INSERT INTO vectors.embeddings (content, collection_name, metadata)
VALUES ('Hello world', 'test_docs', '{"type": "greeting"}');
```

### 4. Configure Your Application
Use the connection details from the verification section to connect your applications.

### 5. Set Up Backups
```bash
# Create first backup
./scripts/backup.sh full

# Schedule daily backups (crontab)
0 2 * * * /path/to/supabase/scripts/backup.sh full
```

## 📚 Documentation Links

- [Complete README](./README.md)
- [Port Configuration](./PORTS.md)
- [Vector Database Usage](./README.md#-vector-database-usage)
- [Backup & Restore](./README.md#-database-backup--restore)

---

**✨ Congratulations!** Your Supabase stack with PostgreSQL 17 and vector support is ready!