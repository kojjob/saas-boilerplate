# SaaS Boilerplate

A production-ready, full-featured SaaS boilerplate built with Ruby on Rails 8. This boilerplate provides all the essential features needed to launch a modern SaaS application, including multi-tenancy, authentication, billing, team management, and more.

## Features

- **Multi-Tenant Architecture**: Row-level multi-tenancy with acts_as_tenant
- **Authentication**: Rails 8 built-in authentication + OAuth (Google, GitHub)
- **Team Management**: Invite team members, manage roles (owner, admin, member)
- **Role-Based Access Control**: Pundit policies with fine-grained permissions
- **Subscription Billing**: Stripe integration via Pay gem (free, pro, enterprise plans)
- **Admin Dashboard**: Metrics, user management, impersonation
- **REST API**: Versioned API (v1) with JWT authentication and rate limiting
- **Real-Time Notifications**: Turbo Streams with Solid Cable
- **Activity Logging**: Paper Trail for audit trails
- **Background Jobs**: Solid Queue for async processing
- **Performance**: Solid Cache for high-performance caching
- **Deployment**: Kamal 2 deployment configuration

## Tech Stack

- **Framework**: Ruby on Rails 8.0+
- **Ruby**: 3.3+
- **Database**: PostgreSQL 16+
- **Frontend**: Hotwire (Turbo + Stimulus) + TailwindCSS
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Deployment**: Kamal 2
- **Testing**: RSpec with 90%+ coverage

## Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Node.js 20+ (for asset compilation)
- Redis (optional, for ActionCable in development)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/kojjob/saas-boilerplate.git
cd saas-boilerplate
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure environment variables

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 4. Setup the database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 5. Start the development server

```bash
bin/dev
```

Visit `http://localhost:3000` to see the application.

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection URL | Yes |
| `RAILS_MASTER_KEY` | Rails credentials key | Yes |
| `STRIPE_PUBLISHABLE_KEY` | Stripe public key | For billing |
| `STRIPE_SECRET_KEY` | Stripe secret key | For billing |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret | For billing |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | For OAuth |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | For OAuth |
| `GITHUB_CLIENT_ID` | GitHub OAuth client ID | For OAuth |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret | For OAuth |

### Stripe Setup

1. Create a Stripe account at https://stripe.com
2. Get your API keys from the Dashboard
3. Create products and prices for your plans
4. Configure webhook endpoint: `https://yourdomain.com/pay/webhooks/stripe`

### OAuth Setup

#### Google OAuth
1. Go to Google Cloud Console
2. Create OAuth 2.0 credentials
3. Add authorized redirect URI: `https://yourdomain.com/auth/google_oauth2/callback`

#### GitHub OAuth
1. Go to GitHub Developer Settings
2. Create a new OAuth App
3. Add callback URL: `https://yourdomain.com/auth/github/callback`

## Development

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Run with auto-correct
bundle exec rubocop --autocorrect-all

# Run security scanner
bundle exec brakeman
```

### Background Jobs

```bash
# Start Solid Queue worker
bin/rails solid_queue:start

# Or use bin/dev which starts all processes
bin/dev
```

### Console

```bash
bin/rails console
```

## Architecture

### Directory Structure

```
app/
├── controllers/
│   ├── admin/           # Admin dashboard controllers
│   ├── api/v1/          # API controllers
│   └── ...              # Main application controllers
├── models/
│   ├── concerns/        # Model concerns (Cacheable, etc.)
│   └── ...              # ActiveRecord models
├── policies/            # Pundit authorization policies
├── services/            # Service objects
├── jobs/                # Background job classes
├── mailers/             # Mailer classes
├── views/
│   ├── layouts/         # Application layouts
│   └── ...              # View templates
└── components/          # ViewComponents (if used)
```

### Multi-Tenancy

This boilerplate uses row-level multi-tenancy with `acts_as_tenant`:

```ruby
# All tenant-scoped models include:
acts_as_tenant(:account)

# Current tenant is set automatically via subdomain or session
class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_action :set_current_account
end
```

### Authentication

Authentication is built on Rails 8's built-in authentication with extensions:

- Email/password login with confirmation
- Password reset flow
- Session management (view/revoke active sessions)
- OAuth providers (Google, GitHub)
- Remember me functionality

### Authorization

Pundit policies provide role-based access control:

```ruby
# Check authorization in controllers
authorize @resource

# Available roles: owner, admin, member
# Custom permissions can be added via the Permission model
```

## API Documentation

The API is versioned and uses JWT authentication:

```bash
# Get API token
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

# Use token in requests
GET /api/v1/users
Authorization: Bearer <token>
```

See `docs/API.md` for complete API documentation.

## Deployment

### Kamal Deployment

```bash
# Initial setup
kamal setup

# Deploy
kamal deploy

# Rollback
kamal rollback

# View logs
kamal app logs
```

### Environment Setup

1. Configure `config/deploy.yml` with your server details
2. Set up Docker registry credentials
3. Configure SSL certificates (Let's Encrypt via Kamal Proxy)

See `docs/DEPLOYMENT.md` for detailed deployment instructions.

## Testing

The test suite includes:

- **Model tests**: Validations, associations, business logic
- **Request tests**: Controller/API endpoint testing
- **System tests**: End-to-end browser testing
- **Mailer tests**: Email functionality
- **Job tests**: Background job processing

Coverage target: 90%+

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests first (TDD)
4. Implement your changes
5. Ensure all tests pass (`bundle exec rspec`)
6. Ensure code quality (`bundle exec rubocop`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/kojjob/saas-boilerplate/issues)
