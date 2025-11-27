# Architecture Documentation

This document describes the architecture of the SaaS Boilerplate application.

## Overview

The application follows a traditional Rails MVC architecture with some additional patterns for scalability and maintainability:

```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                          │
│                    (Kamal Proxy/Nginx)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Rails Application                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐  │
│  │ Controllers │ │   Views     │ │      Models         │  │
│  │   + API     │ │ (Hotwire)   │ │ (ActiveRecord)      │  │
│  └─────────────┘ └─────────────┘ └─────────────────────┘  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐  │
│  │  Policies   │ │  Services   │ │       Jobs          │  │
│  │  (Pundit)   │ │             │ │   (Solid Queue)     │  │
│  └─────────────┘ └─────────────┘ └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌───────────────────┐ ┌─────────────┐ ┌─────────────────┐
│    PostgreSQL     │ │ Solid Cache │ │   Solid Cable   │
│    (Database)     │ │  (Caching)  │ │  (WebSockets)   │
└───────────────────┘ └─────────────┘ └─────────────────┘
```

## Core Concepts

### Multi-Tenancy

The application uses row-level multi-tenancy via the `acts_as_tenant` gem:

```ruby
# Account is the tenant model
class Account < ApplicationRecord
  # Tenanted resources belong to an account
end

# All tenant-scoped models include:
class Project < ApplicationRecord
  acts_as_tenant(:account)
end
```

**Tenant Resolution:**
1. Session-based: `session[:account_id]` stores current account
2. Subdomain-based: `acme.example.com` resolves to `acme` account
3. API: Account determined from authenticated user's default account

### Authentication Flow

```
┌─────────┐     ┌──────────────┐     ┌─────────────┐
│  User   │────▶│ SessionsCtrl │────▶│   Session   │
└─────────┘     └──────────────┘     │   Model     │
                       │             └─────────────┘
                       ▼
              ┌──────────────────┐
              │ Authentication   │
              │ Concern          │
              │ - require_auth   │
              │ - current_user   │
              │ - sign_in/out    │
              └──────────────────┘
```

**Session Management:**
- Sessions stored in database (`sessions` table)
- Tracks IP address, user agent, last accessed
- Users can view and revoke active sessions

### Authorization (Pundit)

```ruby
# Policy structure
class ProjectPolicy < ApplicationPolicy
  def show?
    user_is_member?
  end

  def update?
    user_is_admin_or_owner?
  end

  def destroy?
    user_is_owner?
  end

  class Scope < Scope
    def resolve
      scope.where(account: user.current_account)
    end
  end
end
```

**Role Hierarchy:**
```
owner > admin > member > guest
```

### Request Lifecycle

```
1. Request arrives
   │
2. Rack Middleware (rate limiting, CORS)
   │
3. ApplicationController
   │ ├── set_current_account (multi-tenancy)
   │ ├── require_authentication (auth check)
   │ └── set_locale (i18n)
   │
4. Specific Controller Action
   │ ├── authorize (Pundit policy check)
   │ └── Business logic
   │
5. View Rendering
   │ ├── Turbo Frames/Streams
   │ └── JSON (API)
   │
6. Response
```

## Data Model

### Core Models

```
┌─────────────┐       ┌─────────────────┐       ┌─────────────┐
│   Account   │◄──────│   Membership    │──────▶│    User     │
│             │       │                 │       │             │
│ - name      │       │ - role          │       │ - email     │
│ - slug      │       │ - invitation_*  │       │ - password  │
│ - plan      │       │                 │       │ - confirmed │
└─────────────┘       └─────────────────┘       └─────────────┘
       │                                               │
       │                                               │
       ▼                                               ▼
┌─────────────┐                               ┌─────────────┐
│   Plans     │                               │  Sessions   │
│ (Billing)   │                               │             │
│             │                               │ - ip_addr   │
│ - name      │                               │ - user_agt  │
│ - price     │                               │ - last_at   │
│ - features  │                               └─────────────┘
└─────────────┘
```

### Soft Deletes

Models use `discard` gem for soft deletes:

```ruby
class Account < ApplicationRecord
  include Discard::Model

  # Records are marked as discarded, not deleted
  # Use: account.discard / account.undiscard
  # Queries: Account.kept / Account.discarded
end
```

## API Architecture

### Versioning

```
/api/v1/...    # Current stable version
/api/v2/...    # Future version (when needed)
```

### Authentication Methods

1. **JWT Tokens** (for mobile/SPA):
   ```
   Authorization: Bearer <jwt_token>
   ```

2. **API Keys** (for server-to-server):
   ```
   X-API-Key: <api_key>
   ```

### Rate Limiting

```ruby
# Rack::Attack configuration
throttle('api/ip', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/')
end
```

## Background Jobs

### Solid Queue Configuration

```yaml
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 5
      processes: 2
```

### Job Priorities

| Queue | Priority | Use Case |
|-------|----------|----------|
| critical | 0 | Payments, security |
| default | 10 | Standard processing |
| low | 20 | Reports, cleanup |
| mailers | 15 | Email delivery |

## Caching Strategy

### Cache Layers

1. **HTTP Caching**: ETags, Cache-Control headers
2. **Fragment Caching**: View partials with Solid Cache
3. **Low-Level Caching**: Rails.cache for computed values
4. **Database Caching**: Counter caches, materialized views

### Cache Keys

```ruby
# Cacheable concern provides:
cache_key_for(id)           # "users/123"
cache_key_with_version      # "users/123-20240115120000"
```

## Real-Time Updates

### Turbo Streams

```ruby
# Model broadcasts
class Comment < ApplicationRecord
  after_create_commit { broadcast_append_to "comments" }
  after_update_commit { broadcast_replace_to "comments" }
  after_destroy_commit { broadcast_remove_to "comments" }
end
```

### Solid Cable

```yaml
# config/cable.yml
production:
  adapter: solid_cable
  polling_interval: 0.1.seconds
```

## Security

### Authentication Security
- Password hashing with bcrypt (cost factor 12)
- Session tokens rotated on authentication
- Failed login rate limiting
- Account lockout after 5 failed attempts

### Data Protection
- All data encrypted at rest (PostgreSQL)
- TLS 1.3 for data in transit
- Sensitive fields encrypted with ActiveRecord Encryption

### CSRF Protection
- Enabled for all non-API requests
- API uses stateless JWT (no CSRF needed)

### Content Security Policy
```ruby
# Configured in config/initializers/content_security_policy.rb
policy.default_src :self
policy.script_src  :self
policy.style_src   :self, :unsafe_inline
```

## Performance Considerations

### Database Optimization
- Proper indexing on foreign keys and frequently queried columns
- Counter caches for has_many counts
- Eager loading to prevent N+1 queries

### Query Optimization
```ruby
# Use includes for eager loading
User.includes(:account, :memberships).where(...)

# Use pluck for simple value extraction
User.where(active: true).pluck(:email)
```

### Connection Pooling
```yaml
# config/database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

## Deployment Architecture

### Kamal 2 Setup

```
┌─────────────────────────────────────────────┐
│              Production Server               │
│                                             │
│  ┌─────────────┐     ┌─────────────────┐   │
│  │ Kamal Proxy │────▶│   Rails App     │   │
│  │ (SSL/LB)    │     │   Container     │   │
│  └─────────────┘     └─────────────────┘   │
│                             │               │
│  ┌─────────────────────────────────────┐   │
│  │        PostgreSQL Container         │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Zero-Downtime Deployments

1. New container starts
2. Health check passes
3. Traffic shifts to new container
4. Old container gracefully stops

## Monitoring & Observability

### Health Checks
- `GET /up` - Application health
- `GET /health` - Detailed status (authenticated)

### Logging
- Structured JSON logging in production
- Request ID tracking
- User/tenant context in logs

### Error Tracking
- Sentry integration for exception monitoring
- Alert thresholds configured
