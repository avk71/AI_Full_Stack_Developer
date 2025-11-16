# Self-Hosted Supabase - API Reference

## 🌐 Service Endpoints

### **Base URLs**
- **API Gateway:** `http://172.29.172.1:8000`
- **Studio UI:** `http://172.29.172.1:3000`
- **Database:** `172.29.172.1:5432`

---

## 📡 **REST API (PostgREST)**

### **Base Endpoint**
```
GET http://172.29.172.1:8000/rest/v1/
```

### **Authentication Headers**
```bash
# API Key (if configured)
Authorization: Bearer YOUR_ANON_KEY

# Service Role (full access)
Authorization: Bearer YOUR_SERVICE_ROLE_KEY
```

### **Common Operations**

#### **List Tables**
```bash
curl -X GET "http://172.29.172.1:8000/rest/v1/" \
  -H "Accept: application/json"
```

#### **Query Data**
```bash
curl -X GET "http://172.29.172.1:8000/rest/v1/your_table" \
  -H "Accept: application/json"
```

#### **Insert Data**
```bash
curl -X POST "http://172.29.172.1:8000/rest/v1/your_table" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"column1": "value1", "column2": "value2"}'
```

#### **Update Data**
```bash
curl -X PATCH "http://172.29.172.1:8000/rest/v1/your_table?id=eq.1" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"column1": "new_value"}'
```

#### **Delete Data**
```bash
curl -X DELETE "http://172.29.172.1:8000/rest/v1/your_table?id=eq.1" \
  -H "Prefer: return=representation"
```

---

## 🔐 **Authentication API (GoTrue)**

### **Base Endpoint**
```
http://172.29.172.1:8000/auth/v1/
```

### **Health Check**
```bash
curl -X GET "http://172.29.172.1:8000/auth/v1/health"
```

### **User Registration**
```bash
curl -X POST "http://172.29.172.1:8000/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-secure-password"
  }'
```

### **User Login**
```bash
curl -X POST "http://172.29.172.1:8000/auth/v1/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-secure-password"
  }'
```

### **Get User Info**
```bash
curl -X GET "http://172.29.172.1:8000/auth/v1/user" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### **Logout**
```bash
curl -X POST "http://172.29.172.1:8000/auth/v1/logout" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📁 **Storage API**

### **Base Endpoint**
```
http://172.29.172.1:8000/storage/v1/
```

### **List Buckets**
```bash
curl -X GET "http://172.29.172.1:8000/storage/v1/bucket" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### **Create Bucket**
```bash
curl -X POST "http://172.29.172.1:8000/storage/v1/bucket" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "my-bucket",
    "name": "my-bucket",
    "public": false
  }'
```

### **Upload File**
```bash
curl -X POST "http://172.29.172.1:8000/storage/v1/object/my-bucket/filename.txt" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: text/plain" \
  --data-binary @/path/to/your/file.txt
```

### **Download File**
```bash
curl -X GET "http://172.29.172.1:8000/storage/v1/object/my-bucket/filename.txt" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

---

## 🔄 **Realtime API**

### **WebSocket Endpoint**
```
ws://172.29.172.1:8000/realtime/v1/websocket
```

### **JavaScript Example**
```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://172.29.172.1:8000'
const supabaseKey = 'YOUR_ANON_KEY'

const supabase = createClient(supabaseUrl, supabaseKey)

// Subscribe to table changes
const subscription = supabase
  .channel('your-table-changes')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'your_table' }, 
    (payload) => {
      console.log('Change received!', payload)
    }
  )
  .subscribe()
```

---

## 💾 **Database Access**

### **Direct PostgreSQL Connection**
```bash
# Using psql
psql -h 172.29.172.1 -p 5432 -U supabase_admin -d postgres

# Connection string
postgresql://supabase_admin:HWcns2tWSTXEWRwUGTtsTDfBM9vyCMdn@172.29.172.1:5432/postgres
```

### **Available Schemas**
- `public` - Your application tables
- `auth` - Authentication system
- `storage` - File storage metadata  
- `realtime` - Real-time subscriptions
- `vectors` - Vector similarity search (AI/ML)

### **Vector Search Example**
```sql
-- Create table with vector column
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding vector(1536)
);

-- Insert vector data
INSERT INTO documents (content, embedding) 
VALUES ('Sample text', '[0.1, 0.2, 0.3, ...]');

-- Vector similarity search
SELECT content, 
       embedding <-> '[0.1, 0.2, 0.3, ...]' AS distance
FROM documents 
ORDER BY distance 
LIMIT 5;
```

---

## 🔑 **Authentication in Applications**

### **Environment Configuration**
```bash
# .env file
SUPABASE_URL=http://172.29.172.1:8000
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### **JavaScript/TypeScript Client**
```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseKey)

// Example usage
const { data, error } = await supabase
  .from('your_table')
  .select('*')
```

### **Python Client**
```python
import os
from supabase import create_client, Client

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_ANON_KEY")

supabase: Client = create_client(url, key)

# Example usage
data = supabase.table("your_table").select("*").execute()
```

---

## 🏥 **Health Check Endpoints**

```bash
# Service health checks
curl http://172.29.172.1:8000/auth/v1/health      # Auth service
curl http://172.29.172.1:8000/rest/v1/            # Database API
curl http://172.29.172.1:8000/storage/v1/         # Storage API
curl http://172.29.172.1:3000/                    # Studio UI
```

---

## 📊 **Monitoring and Logs**

### **Container Logs**
```bash
# View real-time logs
docker logs -f supabase_postgres_17
docker logs -f supabase_auth  
docker logs -f supabase_kong

# View recent logs
docker logs supabase_postgres_17 --tail 50
```

### **Database Activity**
```sql
-- View active connections
SELECT * FROM pg_stat_activity;

-- View database size
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database;
```

This API reference covers the essential endpoints and usage patterns for your self-hosted Supabase stack.