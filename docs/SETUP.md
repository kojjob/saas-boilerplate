# Local Development Setup

This guide walks you through setting up the SaaS Boilerplate for local development.

## Prerequisites

### Required Software

| Software | Version | Installation |
|----------|---------|--------------|
| Ruby | 3.4.3+ | [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/) |
| PostgreSQL | 16+ | `brew install postgresql@16` |
| Node.js | 20+ | `brew install node` |
| Redis | 7+ (optional) | `brew install redis` |

### Verify Installation

```bash
ruby --version    # Should be 3.4.3+
psql --version    # Should be 16+
node --version    # Should be 20+
```

## Step-by-Step Setup

### 1. Clone the Repository

```bash
git clone https://github.com/kojjob/saas-boilerplate.git
cd saas-boilerplate
```

### 2. Install Ruby Dependencies

```bash
bundle install
```

If you encounter native extension issues:

```bash
# For macOS with Apple Silicon
bundle config build.pg --with-pg-config=/opt/homebrew/opt/postgresql@16/bin/pg_config
bundle install
```

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your local configuration:

```env
# Database
DATABASE_URL=postgresql://localhost/saas_development

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key_here

# Stripe (use test keys)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# OAuth (optional for development)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
```

### 4. Setup Database

```bash
# Create databases
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Seed with sample data
bin/rails db:seed
```

### 5. Setup Credentials (if needed)

```bash
# Edit credentials (opens in $EDITOR)
EDITOR="code --wait" bin/rails credentials:edit

# Or for development-only credentials
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

### 6. Start the Development Server

```bash
bin/dev
```

This starts:
- Rails server on http://localhost:3000
- Tailwind CSS watcher
- Solid Queue worker

### 7. Access the Application

- **Main App**: http://localhost:3000
- **Default Admin**: admin@example.com / password (seeded)
- **Default User**: user@example.com / password (seeded)

## Development Tools

### Rails Console

```bash
bin/rails console
```

Common console commands:

```ruby
# List all users
User.all

# Find user by email
User.find_by(email: 'admin@example.com')

# Create test account
Account.create!(name: 'Test Account')

# Check current tenant
ActsAsTenant.current_tenant
```

### Database Management

```bash
# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
bin/rails db:reset

# Open database console
bin/rails dbconsole
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run specific test (line 25)
bundle exec rspec spec/models/user_spec.rb:25

# Run with coverage
COVERAGE=true bundle exec rspec

# Run specific type
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
bundle exec rspec spec/system/
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop --autocorrect-all

# Run security scan
bundle exec brakeman

# Check dependencies for vulnerabilities
bundle exec bundler-audit check --update
```

### Background Jobs

Jobs are processed by Solid Queue. In development, `bin/dev` handles this automatically.

```bash
# View pending jobs
bin/rails runner "puts SolidQueue::Job.count"

# Process jobs manually
bin/rails solid_queue:start

# Clear all jobs
bin/rails runner "SolidQueue::Job.delete_all"
```

### Viewing Emails

In development, emails are logged to the console. You can also use:

```ruby
# In rails console
ActionMailer::Base.deliveries.last
```

For a better email preview experience, add letter_opener:

```ruby
# Gemfile (development group)
gem 'letter_opener'

# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
```

## Stripe Setup (Local Testing)

### 1. Install Stripe CLI

```bash
brew install stripe/stripe-cli/stripe
```

### 2. Login to Stripe

```bash
stripe login
```

### 3. Forward Webhooks

```bash
stripe listen --forward-to localhost:3000/pay/webhooks/stripe
```

This outputs a webhook secret - add it to your `.env`:

```env
STRIPE_WEBHOOK_SECRET=whsec_...
```

### 4. Test Payments

Use Stripe test cards:
- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- **Requires Auth**: 4000 0025 0000 3155

## OAuth Setup (Optional)

### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:3000/auth/google_oauth2/callback`
6. Add credentials to `.env`

### GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set Homepage URL: `http://localhost:3000`
4. Set Callback URL: `http://localhost:3000/auth/github/callback`
5. Add credentials to `.env`

## Common Issues

### PostgreSQL Connection Issues

```bash
# Check if PostgreSQL is running
brew services list

# Start PostgreSQL
brew services start postgresql@16

# Check connection
psql -d postgres -c "SELECT 1"
```

### Bundle Install Failures

```bash
# Update bundler
gem update bundler

# Clean and reinstall
rm -rf vendor/bundle
bundle install
```

### Asset Compilation Issues

```bash
# Clear asset cache
bin/rails assets:clobber

# Recompile
bin/rails assets:precompile
```

### Database Migration Issues

```bash
# Check migration status
bin/rails db:migrate:status

# Redo last migration
bin/rails db:migrate:redo
```

## IDE Setup

### VS Code

Recommended extensions:
- Ruby LSP
- Ruby Solargraph
- Rails
- Tailwind CSS IntelliSense
- ERB Formatter/Beautify

`.vscode/settings.json`:
```json
{
  "ruby.lsp.enabled": true,
  "ruby.lsp.formatter": "rubocop",
  "editor.formatOnSave": true,
  "[ruby]": {
    "editor.defaultFormatter": "Shopify.ruby-lsp"
  }
}
```

### RubyMine

RubyMine has built-in support for Rails. Just open the project folder.

## Next Steps

- Read the [Architecture Overview](ARCHITECTURE.md)
- Explore the [API Documentation](API.md)
- Review [Deployment Guide](DEPLOYMENT.md) for production setup
