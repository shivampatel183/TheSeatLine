# docker/redis/init.sh
#!/bin/bash
# Redis Initialization Script

# Create Redis users and ACL
redis-cli --tls --cacert /usr/local/etc/redis/certs/ca.crt \
  ACL SETUSER eventbooking on \
  >${REDIS_PASSWORD:-StrongRedisPassword123!} \
  ~* &* +@all

# Create namespaces
redis-cli --tls --cacert /usr/local/etc/redis/certs/ca.crt \
  SET "eventbooking:metadata:version" "1.0.0"

# Set default TTL for cache keys (24 hours)
redis-cli --tls --cacert /usr/local/etc/redis/certs/ca.crt \
  CONFIG SET maxmemory-policy "allkeys-lru"

# Enable keyspace notifications
redis-cli --tls --cacert /usr/local/etc/redis/certs/ca.crt \
  CONFIG SET notify-keyspace-events "Ex"

echo "Redis initialization completed"