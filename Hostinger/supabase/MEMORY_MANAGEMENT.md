# Supabase Memory Management Guide

## PostgreSQL Memory Configuration (Biggest Impact)

### Current Settings in stack.env:
```env
POSTGRES_MEMORY_LIMIT=2G          # Maximum memory PostgreSQL can use
POSTGRES_MEMORY_RESERVATION=1G    # Guaranteed memory allocation
```

### Memory Profiles for Different Server Sizes:

#### Small Server (4GB RAM):
POSTGRES_MEMORY_LIMIT=1.5G
POSTGRES_MEMORY_RESERVATION=512M

#### Medium Server (8GB RAM):
POSTGRES_MEMORY_LIMIT=3G
POSTGRES_MEMORY_RESERVATION=1.5G

#### Large Server (16GB RAM):
POSTGRES_MEMORY_LIMIT=6G
POSTGRES_MEMORY_RESERVATION=3G

#### Production Server (32GB RAM):
POSTGRES_MEMORY_LIMIT=12G
POSTGRES_MEMORY_RESERVATION=8G

## PostgreSQL Internal Memory Settings

### Current optimized settings in docker-compose.yml:
- shared_buffers=256MB           # Buffer pool for frequently accessed data
- effective_cache_size=1GB       # Available OS cache for PostgreSQL
- maintenance_work_mem=64MB      # Memory for maintenance operations
- work_mem=4MB                   # Memory per query operation

### Memory Tuning by Server Size:

#### Small Server (4GB RAM) - Conservative:
shared_buffers=128MB
effective_cache_size=512MB
maintenance_work_mem=32MB
work_mem=2MB

#### Medium Server (8GB RAM) - Balanced:
shared_buffers=512MB
effective_cache_size=2GB
maintenance_work_mem=128MB
work_mem=8MB

#### Large Server (16GB RAM) - Performance:
shared_buffers=1GB
effective_cache_size=4GB
maintenance_work_mem=256MB
work_mem=16MB

#### Production Server (32GB+ RAM) - High Performance:
shared_buffers=2GB
effective_cache_size=8GB
maintenance_work_mem=512MB
work_mem=32MB

## Service Memory Limits

### Add memory limits to other services in docker-compose.yml:

```yaml
# Example service with memory limits
studio:
  deploy:
    resources:
      limits:
        memory: 512M
      reservations:
        memory: 256M

kong:
  deploy:
    resources:
      limits:
        memory: 256M
      reservations:
        memory: 128M
```

## Memory Monitoring Commands

### Check current memory usage:
```bash
# Container memory usage
docker stats

# Specific container memory
docker stats supabase_postgres_17

# System memory
free -h

# PostgreSQL memory usage
docker exec supabase_postgres_17 psql -U postgres -c "
  SELECT
    setting AS shared_buffers,
    unit
  FROM pg_settings
  WHERE name = 'shared_buffers';
"
```

### Memory optimization queries:
```sql
-- Check PostgreSQL memory usage
SELECT name, setting, unit FROM pg_settings
WHERE name IN (
  'shared_buffers',
  'effective_cache_size',
  'work_mem',
  'maintenance_work_mem'
);

-- Check buffer hit ratio (should be >95%)
SELECT
  round(
    (blks_hit::float / (blks_read + blks_hit + 1) * 100)::numeric, 2
  ) AS buffer_hit_ratio_percent
FROM pg_stat_database
WHERE datname = 'supabase';
```

## Memory Optimization Strategies

### 1. Database Optimization:
- Regular VACUUM and ANALYZE
- Proper indexing strategy
- Query optimization
- Connection pooling

### 2. Service Optimization:
- Add memory limits to prevent runaway containers
- Use memory reservations for guaranteed allocation
- Monitor and adjust based on actual usage

### 3. System-Level:
- Enable swap (but minimize usage)
- Monitor disk I/O impact
- Consider SSD for database storage

### 4. Vector Search Optimization:
- Use appropriate vector index types (HNSW vs IVFFLAT)
- Tune vector search parameters
- Consider vector dimension reduction

## Memory Alerts and Monitoring

### Docker memory alerts:
```bash
# Create memory monitoring script
cat > monitor_memory.sh << 'EOF'
#!/bin/bash
echo "=== Supabase Memory Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""
echo "=== System Memory ==="
free -h
EOF

chmod +x monitor_memory.sh
```

### PostgreSQL memory monitoring:
```sql
-- Check for memory pressure
SELECT
  name,
  setting,
  unit,
  context
FROM pg_settings
WHERE name LIKE '%mem%'
ORDER BY name;
```

## Troubleshooting Memory Issues

### Signs of memory pressure:
- High swap usage
- Slow query performance
- Container restarts (OOMKilled)
- High disk I/O wait

### Quick fixes:
1. Reduce PostgreSQL limits temporarily
2. Add swap space
3. Restart heavy services
4. Clear PostgreSQL logs

### Long-term solutions:
1. Upgrade server RAM
2. Optimize database queries
3. Add read replicas
4. Implement caching layer