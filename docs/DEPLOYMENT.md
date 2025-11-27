# Deployment Guide

This guide covers deploying the SaaS Boilerplate to production using Kamal 2.

## Prerequisites

- Docker installed locally
- SSH access to your server(s)
- Domain name with DNS configured
- Docker registry account (Docker Hub, GitHub Container Registry, etc.)

## Server Requirements

### Minimum Requirements

- **CPU:** 2 cores
- **RAM:** 4GB
- **Storage:** 50GB SSD
- **OS:** Ubuntu 22.04 LTS (recommended)

### Recommended for Production

- **CPU:** 4+ cores
- **RAM:** 8GB+
- **Storage:** 100GB+ SSD
- **Database:** Dedicated PostgreSQL instance

## Initial Server Setup

### 1. SSH Access

Ensure you can SSH to your server:

```bash
ssh root@your-server-ip
```

### 2. Install Docker

Kamal will install Docker if not present, but you can install manually:

```bash
curl -fsSL https://get.docker.com | sh
```

### 3. Configure Firewall

```bash
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw enable
```

## Kamal Configuration

### 1. Configure deploy.yml

Edit `config/deploy.yml`:

```yaml
service: saas-boilerplate
image: your-registry/saas-boilerplate

servers:
  web:
    - your-server-ip
    labels:
      traefik.http.routers.saas-boilerplate.rule: Host(`yourdomain.com`)

proxy:
  ssl: true
  host: yourdomain.com

registry:
  server: ghcr.io  # or docker.io for Docker Hub
  username:
    - KAMAL_REGISTRY_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_LEVEL: info
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - STRIPE_SECRET_KEY
    - STRIPE_WEBHOOK_SECRET

accessories:
  db:
    image: postgres:16
    host: your-server-ip
    port: 5432
    env:
      clear:
        POSTGRES_DB: saas_boilerplate_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

healthcheck:
  path: /up
  port: 3000
```

### 2. Configure Secrets

Create `.kamal/secrets`:

```bash
KAMAL_REGISTRY_USERNAME=your_username
KAMAL_REGISTRY_PASSWORD=your_password
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=postgres://postgres:password@your-server-ip:5432/saas_boilerplate_production
POSTGRES_PASSWORD=secure_password
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

**Important:** Never commit this file to version control!

## Deployment Steps

### First Deployment

```bash
# 1. Setup servers and install Docker
kamal setup

# 2. Push environment variables
kamal env push

# 3. Deploy the application
kamal deploy
```

### Subsequent Deployments

```bash
# Standard deploy
kamal deploy

# Deploy with maintenance mode
kamal deploy --skip_push  # If image already pushed
```

### Database Migrations

Migrations run automatically during deployment. For manual execution:

```bash
kamal app exec 'bin/rails db:migrate'
```

## SSL/TLS Configuration

Kamal Proxy automatically handles SSL certificates via Let's Encrypt.

### Requirements

1. Domain DNS pointing to server IP
2. Port 80 and 443 open
3. `ssl: true` in deploy.yml

### Manual Certificate Setup

If you prefer manual certificates:

```yaml
proxy:
  ssl: true
  host: yourdomain.com
  ssl_certificate_path: /path/to/cert.pem
  ssl_private_key_path: /path/to/key.pem
```

## Environment Variables

### Required Variables

| Variable | Description |
|----------|-------------|
| `RAILS_MASTER_KEY` | Encryption key for credentials |
| `DATABASE_URL` | PostgreSQL connection string |
| `RAILS_ENV` | `production` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_LOG_LEVEL` | Log verbosity | `info` |
| `RAILS_MAX_THREADS` | Puma thread count | `5` |
| `WEB_CONCURRENCY` | Puma worker count | `2` |
| `STRIPE_SECRET_KEY` | Stripe API key | - |
| `SENTRY_DSN` | Error tracking | - |

### Managing Secrets

```bash
# View current environment
kamal env list

# Update secrets
kamal env push

# Edit secrets file and push
vim .kamal/secrets
kamal env push
```

## Database Management

### Backups

```bash
# Create backup
kamal accessory exec db 'pg_dump -U postgres saas_boilerplate_production' > backup.sql

# Automated backups (add to crontab on server)
0 2 * * * docker exec saas-boilerplate-db pg_dump -U postgres saas_boilerplate_production | gzip > /backups/db-$(date +\%Y\%m\%d).sql.gz
```

### Restore

```bash
# Restore from backup
cat backup.sql | kamal accessory exec db 'psql -U postgres saas_boilerplate_production'
```

### Database Console

```bash
kamal accessory exec db 'psql -U postgres saas_boilerplate_production'
```

## Monitoring

### Health Checks

The application exposes health endpoints:

- `GET /up` - Basic health check (returns 200 if healthy)
- `GET /health` - Detailed health with dependencies

### Logs

```bash
# View application logs
kamal app logs

# Follow logs
kamal app logs -f

# View specific container logs
kamal app logs --roles=web
```

### Application Console

```bash
kamal app exec -i 'bin/rails console'
```

## Rollback

### Quick Rollback

```bash
kamal rollback
```

### Rollback to Specific Version

```bash
# List available versions
kamal app images

# Rollback to specific version
kamal rollback abc123
```

## Scaling

### Horizontal Scaling

Add more servers in `deploy.yml`:

```yaml
servers:
  web:
    - server1-ip
    - server2-ip
    - server3-ip
```

### Vertical Scaling

Adjust Puma configuration:

```bash
# .kamal/secrets
WEB_CONCURRENCY=4
RAILS_MAX_THREADS=10
```

## Troubleshooting

### Container Won't Start

```bash
# Check container status
kamal app containers

# View boot logs
kamal app logs

# Check configuration
kamal app exec 'bin/rails runner "puts Rails.configuration.inspect"'
```

### Database Connection Issues

```bash
# Test database connectivity
kamal app exec 'bin/rails runner "ActiveRecord::Base.connection.execute(\"SELECT 1\")"'

# Check database container
kamal accessory logs db
```

### SSL Certificate Issues

```bash
# Check certificate status
kamal proxy logs

# Force certificate renewal
kamal proxy reboot
```

### Memory Issues

```bash
# Check memory usage
kamal app exec 'cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"'

# Adjust Puma workers
# Reduce WEB_CONCURRENCY in secrets
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Run tests
        run: bundle exec rspec

      - name: Deploy
        if: success()
        env:
          KAMAL_REGISTRY_USERNAME: ${{ secrets.KAMAL_REGISTRY_USERNAME }}
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
        run: |
          gem install kamal
          kamal deploy
```

## Security Best Practices

1. **Keep secrets secure:** Never commit `.kamal/secrets`
2. **Rotate credentials:** Regularly rotate database passwords and API keys
3. **Use SSH keys:** Disable password authentication
4. **Update regularly:** Keep Docker and system packages updated
5. **Monitor access:** Review SSH access logs regularly
6. **Backup regularly:** Automated daily backups with offsite storage

## Performance Optimization

### Caching

Solid Cache is configured for production. Monitor cache hit rates:

```bash
kamal app exec 'bin/rails runner "puts Rails.cache.stats"'
```

### Database

```bash
# Check slow queries
kamal accessory exec db 'psql -U postgres saas_boilerplate_production -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"'
```

### Asset Delivery

Consider using a CDN for static assets:

```ruby
# config/environments/production.rb
config.asset_host = 'https://cdn.yourdomain.com'
```
