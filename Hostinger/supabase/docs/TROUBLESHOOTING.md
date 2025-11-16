# Supabase Self-Hosted Troubleshooting Guide

## 🔧 Common Issues and Solutions

### **Container Issues**

#### **PostgreSQL Container Won't Start**
```bash
# Check if directories exist and have correct permissions
ls -la /opt/stacks/apps/database/supabase/
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/postgres_data

# Check logs
docker logs supabase_postgres_17 --tail 50
```

#### **Auth Service Restarting**
```bash
# Check for schema conflicts
docker logs supabase_auth --tail 20

# Common fix: Reset and redeploy with clean schema
./reset-and-deploy.sh
```

#### **Kong Gateway Not Responding**
```bash
# Ensure kong.yml exists
ls -la /opt/stacks/apps/database/supabase/kong_config/kong.yml

# Copy config if missing
sudo cp ./kong.yml /opt/stacks/apps/database/supabase/kong_config/
```

### **Database Issues**

#### **UUID vs Text Comparison Errors**
**Symptoms:** Auth service logs show `operator does not exist: uuid = text`

**Solution:** Use minimal auth schema approach:
```sql
-- Let Auth service create its own tables
-- Only create essential enum types
-- See: init/02-auth-schema.sql (current minimal version)
```

#### **Multiple Primary Keys Error**
**Symptoms:** `multiple primary keys for table are not allowed`

**Solution:** Remove primary key constraints from init scripts:
```sql
-- Wrong:
id UUID PRIMARY KEY DEFAULT uuid_generate_v4()

-- Correct:
id UUID DEFAULT uuid_generate_v4()
```

#### **Missing Extensions**
```bash
# Check available extensions
docker exec -it supabase_postgres_17 psql -U postgres -c "\dx"

# Install missing extensions manually
docker exec -it supabase_postgres_17 psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pgvector;"
```

### **Volume and Permission Issues**

#### **Mount Point Errors**
```bash
# Create all required directories
sudo mkdir -p /opt/stacks/apps/database/supabase/{postgres_data,storage_data,kong_config,init}

# Set correct ownership
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/postgres_data
sudo chown -R 70:70 /opt/stacks/apps/database/supabase/storage_data
```

#### **Init Scripts Not Executing**
```bash
# Ensure scripts are copied to correct location
sudo cp ./init/*.sql /opt/stacks/apps/database/supabase/init/

# Check permissions
sudo chmod 644 /opt/stacks/apps/database/supabase/init/*.sql
```

### **Network and Access Issues**

#### **Services Not Accessible from Host**
```bash
# Check if containers are binding to correct interface
docker ps | grep 172.29.172.1

# Verify VPN interface exists
ip addr show | grep 172.29.172.1
```

#### **API Gateway Routing Issues**
```bash
# Test Kong health
curl -s http://172.29.172.1:8000/health

# Test PostgREST through Kong
curl -s http://172.29.172.1:8000/rest/v1/

# Direct PostgREST test (container internal)
docker exec supabase_rest curl -s localhost:3000/
```

### **Service-Specific Problems**

#### **Analytics Service (Non-Critical)**
```bash
# Expected error for self-hosted: missing gcloud.json
# This is normal and doesn't affect core functionality
docker logs supabase_analytics --tail 10
```

**Fix (Optional):**
```bash
# To disable analytics completely, comment out in docker-compose.yml:
# analytics:
#   image: supabase/logflare:1.4.0
#   ...
```

#### **Edge Runtime Service**
```bash
# Check if command is specified correctly
docker logs supabase_vector_service --tail 10

# Service may need specific startup command configuration
```

#### **Studio UI Shows Unhealthy**
```bash
# Studio usually works even when marked unhealthy
# Access at: http://172.29.172.1:3000

# Check if actually running
curl -s http://172.29.172.1:3000/ | grep -i "supabase"
```

---

## 🔄 **Complete Reset Procedure**

When all else fails, use the automated reset script:

```bash
# Stop all containers (via Portainer or command)
# Run complete reset
./reset-and-deploy.sh

# Restart stack via Portainer
```

The script will:
1. Clean up old containers and volumes
2. Recreate all directories with correct permissions
3. Copy updated init scripts and configs
4. Prepare for clean deployment

---

## 🏥 **Health Check Commands**

```bash
# Quick service status
docker ps | grep supabase

# Check specific service logs
docker logs supabase_postgres_17 --tail 20
docker logs supabase_auth --tail 20
docker logs supabase_kong --tail 20

# Test API endpoints
curl -s http://172.29.172.1:8000/rest/v1/ | jq .
curl -s http://172.29.172.1:8000/auth/v1/health
```

---

## 📞 **Debug Information to Collect**

When reporting issues, include:

1. **Container Status:**
   ```bash
   docker ps | grep supabase
   ```

2. **Service Logs:**
   ```bash
   docker logs supabase_postgres_17 --tail 50
   docker logs supabase_auth --tail 50
   ```

3. **Directory Structure:**
   ```bash
   ls -la /opt/stacks/apps/database/supabase/
   ```

4. **Network Configuration:**
   ```bash
   ip addr show | grep 172.29.172.1
   ```

This information helps identify the root cause of deployment issues.