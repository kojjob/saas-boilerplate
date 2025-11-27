# Contributing to SaaS Boilerplate

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/saas-boilerplate.git
cd saas-boilerplate
```

### 2. Set Up Development Environment

```bash
# Install dependencies
bundle install

# Set up the database
bin/rails db:create db:migrate db:seed

# Run the test suite
bundle exec rspec
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

## Development Workflow

### Test-Driven Development (TDD)

We follow TDD principles. Always write tests first:

1. **Red**: Write a failing test
2. **Green**: Write the minimum code to pass
3. **Refactor**: Improve the code while keeping tests green

```bash
# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Style

We use RuboCop for code style enforcement:

```bash
# Check for violations
bundle exec rubocop

# Auto-fix safe violations
bundle exec rubocop --autocorrect

# Auto-fix all (review changes)
bundle exec rubocop --autocorrect-all
```

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```bash
git commit -m "feat(auth): add password reset functionality"
git commit -m "fix(billing): correct tax calculation for EU customers"
git commit -m "docs(api): add authentication examples"
```

## Pull Request Process

### 1. Ensure Quality

Before submitting:

```bash
# Run all tests
bundle exec rspec

# Check code style
bundle exec rubocop

# Run security scanner
bundle exec brakeman

# Ensure no pending migrations
bin/rails db:migrate:status
```

### 2. Update Documentation

- Update README.md if adding features
- Add/update relevant documentation in `docs/`
- Include inline code comments for complex logic

### 3. Create Pull Request

1. Push your branch to your fork
2. Open a PR against `main` branch
3. Fill out the PR template completely
4. Link any related issues

### 4. PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style
- [ ] Self-reviewed my code
- [ ] Commented complex areas
- [ ] Documentation updated
- [ ] No new warnings
```

## Code Guidelines

### Ruby Style

- Use 2 spaces for indentation
- Use snake_case for methods and variables
- Use CamelCase for classes and modules
- Keep methods under 10 lines when possible
- Keep classes under 100 lines when possible

### Rails Conventions

- Follow RESTful routing
- Keep controllers thin
- Use service objects for complex business logic
- Use concerns for shared model behavior
- Use scopes for common queries

### Testing Guidelines

```ruby
# Good test structure
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
  end

  describe '#full_name' do
    it 'returns first and last name combined' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
end
```

### Security

- Never commit secrets or credentials
- Use `Rails.application.credentials` for sensitive data
- Validate and sanitize all user input
- Use strong parameters in controllers
- Follow OWASP guidelines

## Project Structure

```
app/
├── controllers/         # Keep thin, delegate to services
├── models/             # Business logic lives here
│   └── concerns/       # Shared model behavior
├── policies/           # Pundit authorization
├── services/           # Complex business operations
├── jobs/               # Background processing
├── mailers/            # Email sending
└── views/              # Templates and partials

spec/
├── models/             # Unit tests
├── requests/           # Integration tests
├── system/             # E2E browser tests
├── services/           # Service object tests
├── support/            # Shared test helpers
└── factories/          # FactoryBot definitions
```

## Adding New Features

### 1. Models

```ruby
# Create migration
bin/rails generate migration AddStatusToProjects status:integer

# Create model spec first
# spec/models/project_spec.rb
RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end
end

# Then implement
# app/models/project.rb
class Project < ApplicationRecord
  acts_as_tenant(:account)
  validates :name, presence: true
end
```

### 2. Controllers

```ruby
# Write request spec first
# spec/requests/projects_spec.rb
RSpec.describe 'Projects', type: :request do
  describe 'GET /projects' do
    it 'returns projects for current account' do
      # ...
    end
  end
end

# Then implement controller
```

### 3. Services

```ruby
# spec/services/create_project_service_spec.rb
RSpec.describe CreateProjectService do
  describe '#call' do
    it 'creates a project with valid params' do
      # ...
    end
  end
end

# app/services/create_project_service.rb
class CreateProjectService
  def initialize(account:, params:)
    @account = account
    @params = params
  end

  def call
    @account.projects.create!(@params)
  end
end
```

## Reporting Issues

### Bug Reports

Include:
- Ruby and Rails versions
- Steps to reproduce
- Expected vs actual behavior
- Error messages/stack traces
- Screenshots if applicable

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Any relevant examples

## Questions?

- Check existing issues and discussions
- Review documentation in `docs/`
- Open a discussion for general questions

Thank you for contributing!
