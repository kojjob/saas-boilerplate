# SaaS Boilerplate Implementation Plan

## Executive Summary

This document outlines a phased implementation plan for building a production-ready, full-featured SaaS boilerplate using Ruby on Rails 8. The plan follows Test-Driven Development (TDD) principles with each feature developed on its own branch following proper git workflow with pull requests.

**Tech Stack:**
- Ruby on Rails 8.0+ (latest)
- PostgreSQL 15+
- Hotwire (Turbo + Stimulus) + TailwindCSS
- Solid Queue, Solid Cache, Solid Cable (Rails 8 "Solid Trifecta")
- Kamal 2 for deployment
- RSpec for testing

---

## Phase 0: Project Foundation (Days 1-2)

**Branch: `feature/project-setup`**

### 0.1 Rails 8 Application Initialization
- Generate new Rails 8 application with PostgreSQL
- Configure RSpec as test framework
- Set up development environment with Docker Compose
- Initialize Kamal 2 deployment configuration
- Configure Propshaft asset pipeline

### 0.2 Core Gem Configuration
- Testing gems (RSpec, FactoryBot, Faker, Shoulda-Matchers)
- Core functionality (acts_as_tenant, pundit, pay, paper_trail, pagy)
- API gems (jbuilder, rack-cors)
- Monitoring (sentry-ruby, sentry-rails)

### 0.3 Database Schema Design
- Core tables: accounts, users, memberships, sessions

---

## Phase 1: Multi-Tenant Architecture (Days 3-5)

**Branch: `feature/multi-tenancy`**

### 1.1 Account (Tenant) Model
- Row-level multi-tenancy using acts_as_tenant
- Tenant resolution (subdomain/path-based)
- Account settings management

### 1.2 Current Context Management
- Rails 8 Current class for request-scoped attributes
- Context propagation to background jobs

---

## Phase 2: Authentication System (Days 6-10)

**Branch: `feature/authentication`**

### 2.1 Rails 8 Built-in Authentication
- Email confirmation flow
- Password reset functionality
- Session management (view/revoke)
- Remember me functionality

### 2.2 OAuth Provider Integration
- Google, GitHub, Microsoft OAuth
- Account linking for existing users

---

## Phase 3: Team & Organization Management (Days 11-15)

**Branch: `feature/team-management`**

### 3.1 Membership Model
- Role enum (owner, admin, member, guest)
- Invitation system with email
- Membership transfer

### 3.2 Team Management UI
- Turbo Frames for dynamic updates
- Member list with role management
- Invitation management

---

## Phase 4: Role-Based Access Control (Days 16-20)

**Branch: `feature/authorization`**

### 4.1 Pundit Policy Framework
- Role hierarchy implementation
- Policy scopes for collections

### 4.2 Permission System
- Fine-grained permission model
- Permission management UI

---

## Phase 5: Subscription Billing with Stripe (Days 21-28)

**Branch: `feature/billing`**

### 5.1 Pay Gem Integration
- Stripe API configuration
- Webhook processing
- Checkout flow

### 5.2 Subscription Plans & Features
- Free, Pro, Enterprise plans
- Feature flags based on plan
- Trial period management

### 5.3 Billing UI & Customer Portal
- Pricing page
- Subscription management
- Invoice history

---

## Phase 6: Admin Dashboard (Days 29-35)

**Branch: `feature/admin-dashboard`**

### 6.1 Admin Authentication & Authorization
- Separate admin authentication
- Admin audit logging

### 6.2 Admin Dashboard Core
- Key metrics overview
- Account/user management
- Impersonation feature

### 6.3 Admin Analytics & Reports
- MRR/ARR tracking
- User growth charts
- Export functionality

---

## Phase 7: REST API with Versioning (Days 36-42)

**Branch: `feature/api`**

### 7.1 API Foundation
- Versioned API namespace (v1)
- JWT + API key authentication
- Rate limiting

### 7.2 API Resources & Documentation
- Serializers for all resources
- OpenAPI/Swagger documentation

### 7.3 API Key Management
- Key generation and rotation
- Usage tracking

---

## Phase 8: Real-Time Notifications (Days 43-48)

**Branch: `feature/notifications`**

### 8.1 Notification System Core
- Notification model and types
- User preferences

### 8.2 Real-Time Delivery with Turbo Streams
- Solid Cable configuration
- Notification channel

### 8.3 Email Notification Integration
- Notification mailer
- Digest options (immediate, daily, weekly)

---

## Phase 9: Activity Logging & Audit Trail (Days 49-54)

**Branch: `feature/audit-logging`**

### 9.1 PaperTrail Integration
- Version tracking on key models
- Metadata storage (IP, user agent)

### 9.2 Activity Feed
- High-level event tracking
- Activity filtering

### 9.3 Audit Log UI
- Admin audit log viewer
- Version diff visualization

---

## Phase 10: Email Notifications with Templates (Days 55-58)

**Branch: `feature/email-templates`**

### 10.1 Email Template System
- Customizable templates with Liquid
- Template preview

### 10.2 Transactional Email Integration
- SendGrid/Postmark configuration
- Email tracking

---

## Phase 11: Background Jobs with Solid Queue (Days 59-62)

**Branch: `feature/background-jobs`**

### 11.1 Solid Queue Configuration
- Queue priority configuration
- Recurring jobs
- Failure handling

### 11.2 Essential Background Jobs
- SendEmailJob, ProcessWebhookJob
- GenerateReportJob, CleanupJob

---

## Phase 12: Production Infrastructure (Days 63-70)

**Branch: `feature/production-infrastructure`**

### 12.1 Kamal 2 Deployment Configuration
- Docker registry setup
- Kamal Proxy for SSL/TLS
- PostgreSQL accessory

### 12.2 CI/CD with GitHub Actions
- CI workflow for tests
- CD workflow for staging/production
- Security scanning (Brakeman)

### 12.3 Monitoring & Observability
- Sentry error tracking
- Health check endpoints
- Log aggregation

### 12.4 Security Hardening
- Content Security Policy
- Rate limiting (Rack::Attack)
- Security headers

---

## Phase 13: Performance Optimization (Days 71-75)

**Branch: `feature/performance`**

### 13.1 Solid Cache Configuration
- Fragment caching
- Russian Doll caching

### 13.2 Database Optimization
- Index optimization
- N+1 query detection

### 13.3 Asset & Frontend Optimization
- Thruster HTTP/2 proxy
- CDN integration

---

## Phase 14: Testing & Quality Assurance (Days 76-82)

**Branch: `feature/test-coverage`**

### 14.1 Comprehensive Test Suite
- Unit tests (70%)
- Integration tests (20%)
- System tests (10%)
- Coverage target: 90%+

### 14.2 Test Infrastructure
- Parallel test execution
- VCR for external APIs

---

## Phase 15: Documentation & Developer Experience (Days 83-87)

**Branch: `feature/documentation`**

### 15.1 Project Documentation
- README, CONTRIBUTING
- ARCHITECTURE, DEPLOYMENT, API docs

### 15.2 Developer Tooling
- Development Docker Compose
- Seed data generators
- Code quality tools

---

## Dependency Graph

```
Phase 0 (Foundation)
    └── Phase 1 (Multi-Tenancy)
        └── Phase 2 (Authentication)
            ├── Phase 3 (Team Management)
            │   └── Phase 4 (Authorization)
            │       └── Phase 6 (Admin Dashboard)
            ├── Phase 5 (Billing)
            ├── Phase 7 (API)
            ├── Phase 8 (Notifications)
            └── Phase 9 (Audit Logging)
                └── Phase 10 (Email Templates)

Phase 11 (Background Jobs) - Can start after Phase 2
Phase 12 (Infrastructure) - Can start after Phase 5
Phase 13 (Performance) - After Phase 12
Phase 14 (Testing) - Continuous throughout
Phase 15 (Documentation) - Final phase
```

---

## Timeline Summary

| Phase | Days | Complexity |
|-------|------|------------|
| 0: Foundation | 2 | Low |
| 1: Multi-Tenancy | 3 | High |
| 2: Authentication | 5 | Medium |
| 3: Team Management | 5 | High |
| 4: Authorization | 5 | Medium |
| 5: Billing | 8 | Very High |
| 6: Admin Dashboard | 7 | High |
| 7: API | 7 | High |
| 8: Notifications | 6 | Medium |
| 9: Audit Logging | 6 | Medium |
| 10: Email Templates | 4 | Medium |
| 11: Background Jobs | 4 | Medium |
| 12: Infrastructure | 8 | High |
| 13: Performance | 5 | Medium |
| 14: Testing | 7 | High |
| 15: Documentation | 5 | Medium |

**Total: ~87 days (17-18 weeks)**

---

## Git Workflow

Each phase follows TDD workflow:
1. Create branch: `git checkout -b feature/<name>`
2. Write failing tests (Red)
3. Implement code to pass (Green)
4. Refactor (Refactor)
5. Create PR with tests passing
6. Code review and merge
