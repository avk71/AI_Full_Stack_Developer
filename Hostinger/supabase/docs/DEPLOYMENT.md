# Supabase Self-Hosted Deployment Guide

## 📋 Prerequisites

- Docker & Docker Compose installed
- Portainer for container management
- VPN interface configured (172.29.172.1)
- Sufficient disk space for PostgreSQL data

## 🚀 Quick Deployment

### **1. Automated Deployment (Recommended)**

```bash
# Navigate to project directory
cd /home/andy/_projects/AI_Full_Stack_Developer/Hostinger/supabase/

# Run automated deployment script
./reset-and-deploy.sh

# Deploy via Portainer
# - Open Portainer UI
# - Create/update stack using docker-compose.yml
# - Environment file: stack.env
```

### **2. Manual Deployment Steps**

#### **Step 1: Prepare Directories**
```bash
# Create required directories
sudo mkdir -p /opt/stacks/apps/database/supabase/{postgres_data,storage_data,kong_config,init}

# Set PostgreSQL ownership (user ID 70)
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/postgres_data
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/storage_data
```

#### **Step 2: Copy Configuration Files**
```bash
# Copy initialization scripts
sudo cp ./init/*.sql /opt/stacks/apps/database/supabase/init/

# Copy Kong configuration
sudo cp ./kong.yml /opt/stacks/apps/database/supabase/kong_config/

# Set permissions
sudo chmod 644 /opt/stacks/apps/database/supabase/init/*.sql
sudo chmod 644 /opt/stacks/apps/database/supabase/kong_config/kong.yml
```

#### **Step 3: Deploy Stack**
```bash
# Using Docker Compose directly
docker-compose up -d

# OR via Portainer (recommended)
# Upload docker-compose.yml to Portainer
# Set environment file: stack.env
# Deploy stack
```

---

## 📁 **File Structure Overview**

```
supabase/
├── docker-compose.yml           # Main orchestration
├── stack.env                    # Environment variables
├── kong.yml                     # API Gateway config
├── reset-and-deploy.sh          # Deployment automation
├── init/                        # Database initialization
│   ├── 00-create-supabase-admin.sql
│   ├── 01-initial-schema.sql
│   ├── 02-auth-schema.sql       # Minimal auth setup
│   ├── 03-storage-schema.sql
│   ├── 04-vector-schema.sql     # AI/ML vector support
│   └── 05-seed-data.sql
└── docs/                        # Documentation
    ├── DEPLOYMENT-STATUS.md
    ├── TROUBLESHOOTING.md
    └── API-REFERENCE.md
```

---

## ⚙️ **Configuration Details**

### **Environment Variables (stack.env)**

#### **Database Configuration**
```env
POSTGRES_HOST=postgres
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=XtrUS1I6ZoBZWlGETTJMJ6Yz6dSPdhm8
SUPABASE_ADMIN_PASSWORD=HWcns2tWSTXEWRwUGTtsTDfBM9vyCMdn
```

#### **Network Configuration**
```env
# VPN interface binding
POSTGRES_HOST_BIND=172.29.172.1
KONG_HTTP_PORT=8000
KONG_HTTPS_PORT=8443
STUDIO_PORT=3000
```

#### **Service URLs**
```env
API_EXTERNAL_URL=http://172.29.172.1:8000
SUPABASE_URL=http://172.29.172.1:8000
STUDIO_URL=http://172.29.172.1:3000
```

### **Volume Mounts**
```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/stacks/apps/database/supabase/postgres_data

  storage_data:
    driver: local  
    driver_opts:
      type: none
      o: bind
      device: /opt/stacks/apps/database/supabase/storage_data

  kong_config:
    driver: local
    driver_opts:
      type: none
      o: bind  
      device: /opt/stacks/apps/database/supabase/kong_config
```

---

## 🔧 **Service Architecture**

### **Core Services**

#### **PostgreSQL 17 + pgvector**
- **Purpose:** Primary database with vector similarity search
- **Port:** 5432 (bound to 172.29.172.1)
- **Features:** Full SQL, vector operations for AI/ML
- **Health:** Monitored via Docker health checks

#### **GoTrue (Authentication)**
- **Purpose:** User authentication and authorization
- **Internal Port:** 9999
- **Features:** JWT tokens, user management, MFA support
- **Dependencies:** PostgreSQL

#### **PostgREST (Database API)**
- **Purpose:** Automatic REST API for PostgreSQL
- **Internal Port:** 3000  
- **Features:** CRUD operations, filtering, joins
- **Dependencies:** PostgreSQL

#### **Kong (API Gateway)**
- **Purpose:** Request routing and rate limiting
- **Port:** 8000/8443 (bound to 172.29.172.1)
- **Features:** Load balancing, authentication passthrough
- **Dependencies:** PostgreSQL, Kong config file

#### **Storage API**
- **Purpose:** File upload and management
- **Internal Port:** 5000
- **Features:** Bucket management, file operations
- **Dependencies:** PostgreSQL, Storage volume

#### **Realtime**
- **Purpose:** WebSocket connections for live data
- **Features:** Database change subscriptions
- **Dependencies:** PostgreSQL

#### **Supabase Studio**
- **Purpose:** Web-based database administration
- **Port:** 3000 (bound to 172.29.172.1)
- **Features:** Schema design, data browsing, SQL editor
- **Dependencies:** All other services

### **Optional Services**

#### **Analytics (Logflare)**
- **Purpose:** Usage analytics and logging
- **Status:** Requires Google Cloud configuration
- **Impact:** Non-critical for core functionality

#### **Edge Runtime**
- **Purpose:** Serverless function execution
- **Status:** Requires startup command configuration
- **Impact:** Only affects custom edge functions

---

## 🚦 **Deployment Validation**

### **1. Container Status Check**
```bash
docker ps | grep supabase
```

**Expected Output:**
- `supabase_postgres_17` - healthy
- `supabase_kong` - healthy  
- `supabase_auth` - running
- `supabase_studio` - running
- `supabase_storage` - running
- `supabase_rest` - running
- `supabase_realtime` - running
- `supabase_meta` - healthy

### **2. Service Health Tests**
```bash
# Test API Gateway
curl -s http://172.29.172.1:8000/rest/v1/ | jq .

# Test Auth Service  
curl -s http://172.29.172.1:8000/auth/v1/health

# Test Studio UI
curl -s http://172.29.172.1:3000/ | grep -i "supabase"
```

### **3. Database Connectivity**
```bash
# Test PostgreSQL connection
docker exec -it supabase_postgres_17 psql -U supabase_admin -d postgres -c "SELECT version();"

# Check installed extensions
docker exec -it supabase_postgres_17 psql -U supabase_admin -d postgres -c "\\dx"
```

### **4. Log Verification**
```bash
# Check for successful Auth migrations
docker logs supabase_auth | grep "Successfully applied"

# Verify PostgreSQL initialization
docker logs supabase_postgres_17 | grep "database system is ready"

# Check Kong configuration loaded
docker logs supabase_kong | grep -v ERROR
```

---

## 🔄 **Maintenance Operations**

### **Clean Restart**
```bash
# Stop all services (via Portainer)
# Run reset script
./reset-and-deploy.sh
# Restart via Portainer
```

### **Backup Database**
```bash
# Create database backup
docker exec supabase_postgres_17 pg_dump -U supabase_admin postgres > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup specific schema
docker exec supabase_postgres_17 pg_dump -U supabase_admin -n public postgres > public_schema_backup.sql
```

### **Update Configuration**
```bash
# Update environment variables in stack.env
# Copy new init scripts if needed
sudo cp ./init/*.sql /opt/stacks/apps/database/supabase/init/
# Restart stack via Portainer
```

---

## 🎯 **Post-Deployment Setup**

### **1. Access Studio UI**
1. Navigate to: http://172.29.172.1:3000
2. Connect using database credentials
3. Verify all schemas are present (auth, storage, public, vectors)

### **2. Create Application Database Schema**
```sql
-- Connect via Studio or psql
-- Create your application tables in public schema
CREATE TABLE your_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### **3. Set Up Authentication**
- Configure auth settings in Studio
- Set up email templates if needed
- Configure OAuth providers if required

### **4. Test Vector Search (AI/ML)**
```sql
-- Test vector extension
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Create vector table
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536)
);
```

---

## 📚 **Next Steps**

1. **Review [API-REFERENCE.md](./API-REFERENCE.md)** for endpoint details
2. **Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** for common issues  
3. **Monitor [DEPLOYMENT-STATUS.md](./DEPLOYMENT-STATUS.md)** for current state
4. **Configure your applications** to use the deployed services

Your self-hosted Supabase stack is now ready for production use!