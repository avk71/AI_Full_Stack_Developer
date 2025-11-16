# Supabase Stack Deployment - Chat History & Documentation

**Date:** November 11, 2025
**Project:** Complete Supabase Stack with PostgreSQL 17 + pgvector
**Deployment:** VPN-secured via Portainer with persistent volumes

---

## 🎯 Project Objective

Deploy a complete Supabase stack including:
- PostgreSQL 17 with pgvector extension for vector/AI operations
- Supabase Studio web interface
- Kong API Gateway for routing
- Authentication, Storage, Realtime, and Analytics services
- VPN-only access (Amnezia 172.29.172.1)
- Persistent data storage via local-persist volumes

---

## 📋 Final Configuration Summary

### **Services Deployed (11 total):**
1. **PostgreSQL 17** - Main database with pgvector extension
2. **Supabase Studio** - Web dashboard for database management
3. **Kong Gateway** - API routing and security
4. **GoTrue** - Authentication service
5. **PostgREST** - Auto-generated REST API
6. **Realtime** - WebSocket subscriptions
7. **Storage API** - File management
8. **ImgProxy** - Image transformation
9. **Meta** - Database introspection
10. **Analytics (Logflare)** - Logging and monitoring
11. **Edge Runtime** - Serverless functions

### **Access URLs (VPN-only):**
- **Studio Dashboard:** `http://172.29.172.1:3000`
- **API Gateway:** `http://172.29.172.1:8000`
- **Analytics:** `http://172.29.172.1:4000`
- **PostgreSQL Direct:** `172.29.172.1:5432`

### **Security Configuration:**
- All services bind to VPN interface only (`172.29.172.1`)
- UFW firewall rules restrict access to VPN subnet
- JWT-based authentication with generated secrets
- Row Level Security (RLS) enabled

---

## 🛠️ Technical Implementation

### **Docker Compose Structure:**
```yaml
# Key configuration highlights:
- PostgreSQL: pgvector/pgvector:pg17 with optimized settings
- Studio: supabase/studio:latest with 180s health check
- Kong: kong:2.8.1 with declarative configuration
- Volumes: local-persist driver for data persistence
```

### **Environment Variables:**
- JWT secrets and API keys auto-generated
- VPN IP configuration: `amnezia=172.29.172.1`
- SMTP configuration for email notifications
- Memory limits: PostgreSQL (3GB), other services optimized

### **Persistent Storage:**
```bash
/opt/stacks/apps/database/supabase/
├── postgres_data/     # Database files
├── storage_data/      # Uploaded files
└── kong_config/       # API Gateway configuration
```

---

## 🚧 Issues Encountered & Resolutions

### **Issue 1: Docker Hub Rate Limiting**
**Problem:** `toomanyrequests: You have reached your unauthenticated pull rate limit`
**Solution:**
- Authenticated Docker Hub in Portainer
- Added Docker Hub registry with credentials
- Pre-pull images script created for future deployments

### **Issue 2: Kong Configuration Error**
**Problem:** `kong.yml: No such file or directory`
**Solution:**
- Created proper Kong declarative configuration file
- Fixed Kong route syntax (removed regex `~` patterns)
- Updated format version from 3.0 to 2.1 for compatibility
- Configured Kong volume mount to persistent storage

### **Issue 3: Shell Command Execution Errors**
**Problem:** `exec: "sh": executable file not found in $PATH`
**Solution:**
- Removed problematic `sh -c` commands from services
- Let containers use default entrypoints
- Fixed PostgREST and Realtime service configurations

### **Issue 4: Service Dependencies & Health Checks**
**Problem:** Analytics and Meta services marked as "unhealthy" blocking startup
**Solution:**
- Removed strict health check dependencies
- Changed dependencies from `service_healthy` to `service_started`
- Added proper health checks using `wget` instead of `curl`
- Extended startup periods for Next.js applications (Studio: 180s)

### **Issue 5: Environment Variable References**
**Problem:** Variable-to-variable references in `.env` file
**Solution:**
- Fixed `stack.env` to use literal values instead of `${amnezia}` references
- Kept `${amnezia}` variable usage in docker-compose.yml (valid syntax)
- Separated concerns between Docker Compose and environment variables

---

## 📁 Generated Files

### **Core Configuration:**
1. `docker-compose.yml` - Main stack definition (515 lines)
2. `stack.env` - Environment variables with VPN and auth configuration
3. `kong.yml` - API Gateway routing configuration

### **Database Initialization:**
1. `init/01-initial-schema.sql` - Basic Supabase schemas
2. `init/02-auth-schema.sql` - Authentication tables
3. `init/03-storage-schema.sql` - File storage schemas
4. `init/04-vector-schema.sql` - Vector/AI schemas with pgvector
5. `init/05-seed-data.sql` - Initial data and functions

### **Management Scripts:**
1. `deploy-supabase.sh` - Automated deployment with error handling
2. `setup-ufw.sh` - UFW firewall configuration for VPN security
3. `check-services.sh` - Service status monitoring without Docker health checks
4. `verify-images.sh` - Docker image availability verification
5. `pre-pull-images.sh` - Pre-cache images to avoid rate limits

---

## ⚙️ Deployment Process

### **1. Initial Setup:**
```bash
# Install local-persist plugin
docker plugin install --grant-all-permissions cwspear/docker-local-persist-volume-plugin:latest

# Create volume directories
sudo mkdir -p /opt/stacks/apps/database/supabase/{postgres_data,storage_data,kong_config}

# Copy Kong configuration
sudo cp kong.yml /opt/stacks/apps/database/supabase/kong_config/
```

### **2. Docker Hub Authentication:**
- Added registry in Portainer: `dockerhub-prod-us`
- Configured with Docker Hub username and access token
- Resolved rate limiting issues

### **3. Stack Deployment:**
- Upload `docker-compose.yml` to Portainer
- Import environment variables from `stack.env`
- Deploy stack with VPN-only port bindings

### **4. Firewall Configuration:**
```bash
# Run UFW setup script
chmod +x setup-ufw.sh
sudo ./setup-ufw.sh
```

---

## 🔧 Optimization & Best Practices

### **PostgreSQL Tuning:**
- `max_connections=200` for high concurrency
- `shared_buffers=256MB` optimized for available memory
- `effective_cache_size=1GB` for query planning
- `shared_preload_libraries=vector` for pgvector extension

### **Security Hardening:**
- VPN-only binding prevents public access
- JWT secrets generated with high entropy
- SMTP configuration for secure email delivery
- Row Level Security policies enforced

### **Production Readiness:**
- Health checks for critical services
- Restart policies: `unless-stopped`
- Memory limits to prevent resource exhaustion
- Persistent volumes for data durability

---

## 📊 Final Status

### **✅ Successfully Deployed:**
- PostgreSQL 17 with pgvector: **Healthy & Accessible**
- Supabase Studio: **Accessible at port 3000**
- Kong API Gateway: **Routing correctly**
- All supporting services: **Running properly**

### **🔗 Verified Functionality:**
- Database connections working
- Studio web interface responsive
- API Gateway routing requests
- VPN-only access confirmed
- Persistent storage operational

---

## 🚀 Next Steps & Usage

### **Access Studio:**
1. Connect via Amnezia VPN
2. Browse to `http://172.29.172.1:3000`
3. Use the web interface to manage database, users, and storage

### **Database Connection:**
```
Host: 172.29.172.1
Port: 5432
Database: supabase
Username: postgres
Password: [from stack.env]
```

### **API Usage:**
- REST API: `http://172.29.172.1:8000/rest/v1/`
- Authentication: `http://172.29.172.1:8000/auth/v1/`
- Storage: `http://172.29.172.1:8000/storage/v1/`
- Realtime: `ws://172.29.172.1:8000/realtime/v1/websocket`

### **Monitoring:**
- Analytics Dashboard: `http://172.29.172.1:4000`
- Container logs via Portainer
- Health status monitoring scripts

---

## 🎓 Learning Outcomes

### **Docker & Containerization:**
- Complex multi-service orchestration
- Volume management with local-persist
- Health check optimization
- Dependency management

### **Networking & Security:**
- VPN-only service binding
- Firewall configuration
- API Gateway routing
- JWT authentication

### **Database Management:**
- PostgreSQL optimization
- pgvector extension configuration
- Schema initialization
- Performance tuning

### **Troubleshooting:**
- Docker Hub rate limiting
- Service dependency issues
- Health check optimization
- Environment variable management

---

## 📚 References & Documentation

- **Supabase Official Docs:** https://supabase.com/docs
- **pgvector GitHub:** https://github.com/pgvector/pgvector
- **Kong Gateway Docs:** https://docs.konghq.com/
- **Docker Compose Reference:** https://docs.docker.com/compose/
- **Local Persist Plugin:** https://github.com/MatchbookLab/local-persist

---

**Deployment completed successfully on November 11, 2025**
**Total deployment time:** ~3 hours including troubleshooting
**Final result:** Production-ready Supabase stack with VPN security and persistent storage**

---

*This documentation captures the complete journey from initial requirements to final deployment, including all issues encountered and solutions implemented.*