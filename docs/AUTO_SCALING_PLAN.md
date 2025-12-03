# Auto-Scaling Plan: 5000+ Concurrent Users with Kamal Multi-Server

## Executive Summary

This plan outlines a phased approach to scale the SaaS Boilerplate application from ~230 concurrent users to 5000+ concurrent users using Kamal 2.0 multi-server deployment.

| Metric | Current | Target |
|--------|---------|--------|
| **Concurrent Users** | ~230 | 5000+ |
| **Requests/Second** | ~85 | 2000+ |
| **Response Time (P95)** | ~400ms | <200ms |
| **Monthly Cost** | ~$50 | ~$465-670 |

**Platform**: Kamal Multi-Server (keep existing tooling)
**Budget**: Balanced (mix of managed and self-hosted)
**Priority**: App Servers + Load Balancing

---

## Current Architecture (Baseline)

```
┌─────────────────────────────────────────┐
│           Single Server Setup           │
├─────────────────────────────────────────┤
│  Puma (2 workers, 3 threads)            │
│  PostgreSQL (local, 5 connections)      │
│  Solid Queue (database-backed)          │
│  Solid Cache (database-backed)          │
│  Solid Cable (database-backed)          │
│  Thruster (HTTP/2 proxy)                │
└─────────────────────────────────────────┘
         Capacity: ~230 users
```

**Identified Bottlenecks**:
1. Single server = single point of failure
2. Database connection pool (5 connections) limits concurrency
3. No distributed caching layer
4. Background jobs compete with web requests
5. No load balancing for horizontal scaling

---

## Target Architecture (5000+ Users)

```
                    ┌──────────────┐
                    │   CDN        │
                    │ (Cloudflare) │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Load Balancer│
                    │   (Traefik)  │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌───────▼───────┐
│   Web Server  │  │   Web Server  │  │   Web Server  │
│   (Puma x6)   │  │   (Puma x6)   │  │   (Puma x6)   │
│   4GB RAM     │  │   4GB RAM     │  │   4GB RAM     │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    ┌──────▼───────┐
                    │    Redis     │
                    │ (Cache/Jobs) │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  PgBouncer   │
                    │ (Pooling)    │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                                     │
┌───────▼───────┐                     ┌───────▼───────┐
│  PostgreSQL   │◄────Replication────►│  Read Replica │
│   (Primary)   │                     │   (Optional)  │
│   8GB RAM     │                     │   4GB RAM     │
└───────────────┘                     └───────────────┘

┌─────────────────────────────────────────────────────┐
│              Job Servers (Dedicated)                │
├─────────────────────────────────────────────────────┤
│   Solid Queue Worker x2   │   Solid Cable Server    │
│   (Background Jobs)       │   (WebSockets)          │
└─────────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Puma & Database Optimization (Week 1)
**Goal**: 2x capacity improvement (~500 users)

#### 1.1 Optimize Puma Configuration

**File**: `config/puma.rb`
```ruby
# Optimized for production scaling
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Workers based on CPU cores (2-4 per core)
worker_count = ENV.fetch("WEB_CONCURRENCY") { 4 }
workers worker_count

# Preload app for memory efficiency (Copy-on-Write)
preload_app!

# Set up socket location
bind "unix://#{Rails.root.join('tmp/sockets/puma.sock')}"

# Worker lifecycle hooks
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Phased restarts for zero-downtime deployments
nakayoshi_fork: true if ENV.fetch("RAILS_ENV") { "development" } == "production"
```

#### 1.2 Increase Database Connection Pool

**File**: `config/database.yml`
```yaml
production:
  primary:
    <<: *default
    database: saas_production
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i * ENV.fetch("WEB_CONCURRENCY") { 4 }.to_i + 5 %>
    timeout: 5000
    checkout_timeout: 10

    # Connection health checking
    variables:
      statement_timeout: 30000  # 30 second timeout
      lock_timeout: 10000       # 10 second lock timeout
```

#### 1.3 Enable Query Optimization

**File**: `config/environments/production.rb`
```ruby
# Enable prepared statements for query performance
config.active_record.prepared_statements = true

# Database query logging
config.active_record.verbose_query_logs = false
config.active_record.query_log_tags_enabled = true
config.active_record.query_log_tags = [
  :application, :controller, :action, :job
]
```

---

### Phase 2: Redis & Caching Layer (Week 2)
**Goal**: Reduce database load by 60%, improve response times

#### 2.1 Add Redis for Caching

**File**: `Gemfile`
```ruby
# Add Redis for caching and sessions
gem 'redis', '~> 5.0'
gem 'hiredis-client'  # C extension for performance
```

**File**: `config/environments/production.rb`
```ruby
# Redis-backed caching (faster than Solid Cache for high traffic)
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" },
  pool_size: ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i,
  pool_timeout: 5,
  error_handler: -> (method:, returning:, exception:) {
    Rails.logger.error("Redis error: #{exception}")
    Sentry.capture_exception(exception) if defined?(Sentry)
  }
}

# Enable fragment caching
config.action_controller.perform_caching = true
```

#### 2.2 Redis-Backed Rate Limiting

**File**: `config/initializers/rack_attack.rb`
```ruby
# Use Redis for distributed rate limiting
class Rack::Attack
  cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
    namespace: "rack_attack"
  )

  # Throttle all requests by IP (100 requests per minute)
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login attempts
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/sessions" && req.post?
  end

  # Throttle API endpoints more strictly
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api")
  end
end
```

#### 2.3 Session Storage (Redis)

**File**: `config/initializers/session_store.rb`
```ruby
Rails.application.config.session_store :redis_store,
  servers: [ENV.fetch("REDIS_URL") { "redis://localhost:6379/2" }],
  expire_after: 1.week,
  key: "_subcontractor_command_session",
  threadsafe: true,
  secure: Rails.env.production?
```

---

### Phase 3: Multi-Server Kamal Deployment (Week 3)
**Goal**: Horizontal scaling to 3+ web servers

#### 3.1 Multi-Server Kamal Configuration

**File**: `config/deploy.yml`
```yaml
service: subcontractor-command
image: your-registry/subcontractor-command

servers:
  web:
    hosts:
      - 192.168.1.10  # Web Server 1
      - 192.168.1.11  # Web Server 2
      - 192.168.1.12  # Web Server 3
    labels:
      traefik.http.routers.web.rule: Host(`app.yoursite.com`)
      traefik.http.services.web.loadbalancer.healthcheck.path: /up
      traefik.http.services.web.loadbalancer.healthcheck.interval: 10s
    options:
      memory: 4g
      cpus: 2

  job:
    hosts:
      - 192.168.1.20  # Dedicated job server
    cmd: bin/jobs
    options:
      memory: 2g
      cpus: 1

  cable:
    hosts:
      - 192.168.1.21  # Dedicated WebSocket server
    cmd: bin/cable
    options:
      memory: 1g
      cpus: 1

proxy:
  ssl: true
  host: app.yoursite.com
  healthcheck:
    path: /up
    interval: 10

registry:
  server: ghcr.io
  username:
    - KAMAL_REGISTRY_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: "true"
    RAILS_SERVE_STATIC_FILES: "true"
    WEB_CONCURRENCY: 4
    RAILS_MAX_THREADS: 5
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL
    - SENTRY_DSN

accessories:
  redis:
    image: redis:7-alpine
    host: 192.168.1.30
    port: 6379
    cmd: redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru
    directories:
      - data:/data
    options:
      memory: 1g

  db:
    image: postgres:16
    host: 192.168.1.31
    port: 5432
    env:
      clear:
        POSTGRES_USER: subcontractor
        POSTGRES_DB: subcontractor_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
    options:
      memory: 8g
      cpus: 4

traefik:
  options:
    publish:
      - "443:443"
      - "80:80"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "ssl@yoursite.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint: "web"
```

#### 3.2 Health Check Endpoint

**File**: `config/routes.rb`
```ruby
# Health check for load balancer
get "/up", to: "rails/health#show", as: :rails_health_check
```

---

### Phase 4: PgBouncer Connection Pooling (Week 4)
**Goal**: Support 1000+ database connections efficiently

#### 4.1 PgBouncer Configuration

**File**: `config/pgbouncer.ini`
```ini
[databases]
subcontractor_production = host=192.168.1.31 port=5432 dbname=subcontractor_production

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3
server_lifetime = 3600
server_idle_timeout = 600
server_connect_timeout = 15
server_login_retry = 3
query_timeout = 30
query_wait_timeout = 30
client_idle_timeout = 600
```

#### 4.2 Update Database URL

**Environment Variable**:
```bash
# Point to PgBouncer instead of PostgreSQL directly
DATABASE_URL=postgres://user:pass@192.168.1.30:6432/subcontractor_production?prepared_statements=false
```

**Note**: Disable prepared statements when using PgBouncer in transaction mode.

---

### Phase 5: CDN & Static Assets (Week 5)
**Goal**: Offload 80% of bandwidth, global edge caching

#### 5.1 CDN Configuration (Cloudflare)

**File**: `config/environments/production.rb`
```ruby
# CDN for assets
config.asset_host = ENV.fetch("ASSET_HOST") { "https://cdn.yoursite.com" }

# Enable asset digests
config.assets.digest = true
config.assets.compile = false

# Long cache headers for assets
config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000, immutable"
}

# Enable Brotli compression
config.middleware.use Rack::Deflater
```

#### 5.2 Cloudflare Page Rules

```
# Cache static assets aggressively
URL: cdn.yoursite.com/assets/*
Cache Level: Cache Everything
Edge Cache TTL: 1 month

# Bypass cache for API
URL: app.yoursite.com/api/*
Cache Level: Bypass

# Cache health check
URL: app.yoursite.com/up
Cache Level: Bypass
```

---

## Scaling Capacity by Phase

| Phase | Configuration | Concurrent Users | RPS | Est. Cost/mo |
|-------|---------------|------------------|-----|--------------|
| Current | 1 server, 2 workers | ~230 | 85 | $50 |
| Phase 1 | 1 server, 4 workers | ~500 | 150 | $50 |
| Phase 2 | + Redis caching | ~800 | 250 | $80 |
| Phase 3 | 3 web servers | ~2,500 | 600 | $300 |
| Phase 4 | + PgBouncer | ~4,000 | 1,200 | $350 |
| Phase 5 | + CDN | ~5,000+ | 2,000+ | $400-500 |

---

## Server Specifications & Cost Estimate

### Recommended Server Configuration

| Role | Specs | Quantity | Monthly Cost |
|------|-------|----------|--------------|
| **Web Servers** | 4GB RAM, 2 vCPU | 3 | $60 x 3 = $180 |
| **Database** | 8GB RAM, 4 vCPU, SSD | 1 | $160 |
| **Redis** | 2GB RAM, 1 vCPU | 1 | $20 |
| **Job Server** | 2GB RAM, 1 vCPU | 1 | $20 |
| **PgBouncer** | 1GB RAM, 1 vCPU | 1 | $10 |
| **CDN (Cloudflare)** | Pro Plan | 1 | $25 |
| **Monitoring** | Datadog/NewRelic | 1 | $50 |

**Total Estimated Monthly Cost**: $465-670/month

### Provider Recommendations (Balanced Budget)

- **Web/Job Servers**: DigitalOcean Droplets or Hetzner Cloud
- **Database**: DigitalOcean Managed PostgreSQL or self-hosted
- **Redis**: DigitalOcean Managed Redis or self-hosted
- **CDN**: Cloudflare (free tier sufficient for start)
- **DNS**: Cloudflare (free)
- **SSL**: Let's Encrypt via Kamal/Traefik (free)

---

## Monitoring & Alerting

### Key Metrics to Monitor

```yaml
application:
  - request_rate (RPS)
  - response_time_p50
  - response_time_p95
  - response_time_p99
  - error_rate
  - active_connections

database:
  - connection_pool_usage
  - query_duration
  - transactions_per_second
  - replication_lag
  - disk_usage

redis:
  - memory_usage
  - hit_rate
  - evicted_keys
  - connected_clients

infrastructure:
  - cpu_usage
  - memory_usage
  - disk_io
  - network_throughput
```

### Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Response Time P95 | >500ms | >1000ms |
| Error Rate | >1% | >5% |
| CPU Usage | >70% | >90% |
| Memory Usage | >80% | >95% |
| DB Connections | >80% pool | >95% pool |
| Redis Memory | >70% | >90% |

---

## Rollback Strategy

Each phase includes rollback capability:

1. **Kamal Rollback**: `kamal rollback` to previous container version
2. **Database**: Point-in-time recovery enabled
3. **Configuration**: All configs version-controlled in Git
4. **DNS**: 5-minute TTL allows quick failover

---

## Files to Modify (Summary)

| File | Phase | Changes |
|------|-------|---------|
| `config/puma.rb` | 1 | Workers, threads, preload_app |
| `config/database.yml` | 1, 4 | Pool size, PgBouncer URL |
| `config/environments/production.rb` | 1, 2, 5 | Caching, CDN, performance |
| `config/initializers/rack_attack.rb` | 2 | Redis-backed rate limiting |
| `config/deploy.yml` | 3 | Multi-server Kamal config |
| `Gemfile` | 2 | Redis gems |

---

## Quick Start Commands

```bash
# Phase 1: Deploy optimized Puma config
kamal deploy

# Phase 2: Add Redis accessory
kamal accessory boot redis

# Phase 3: Add web servers
kamal app boot --hosts 192.168.1.11,192.168.1.12

# Run benchmark after each phase
BASE_URL=https://app.yoursite.com bin/benchmark stress

# View logs across all servers
kamal app logs -f

# Scale specific role
kamal app boot web --hosts new-server-ip
```

---

## Success Criteria

- [ ] 5000+ concurrent users without errors
- [ ] P95 response time < 200ms
- [ ] 99.9% uptime SLA achievable
- [ ] Zero-downtime deployments
- [ ] Automatic failover capability
- [ ] Cost within $500-700/month budget

---

*Generated: December 2025*
*Benchmark Report: docs/PERFORMANCE_BENCHMARK_REPORT.md*
