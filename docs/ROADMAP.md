# Subcontractor Command - Development Roadmap

> Last Updated: December 10, 2025

## User Decisions (Captured)
- **Priority**: Tier 1 Critical features
- **Client Portal**: Token-based access (no login required)
- **Recurring Invoices**: Queue for review before sending

---

## Progress Overview

| Feature | Status | PR |
|---------|--------|-----|
| Estimate PDF & Email | ✅ Complete | [#54](https://github.com/kojjob/saas-boilerplate/pull/54) |
| User Onboarding Checklist | ✅ Complete | [#55](https://github.com/kojjob/saas-boilerplate/pull/55) |
| Client Portal (Token-Based) | 🔲 Not Started | - |
| Bulk Invoice from Time/Materials | 🔲 Not Started | - |

---

## Already Implemented (Prior Work)

| Feature | Status | Evidence |
|---------|--------|----------|
| Invoice PDF Generation | ✅ Done | `app/services/pdf/invoice_pdf_generator.rb` |
| Invoice Mailer | ✅ Done | `app/mailers/invoice_mailer.rb` |
| Payment Reminders | ✅ Done | `app/jobs/payment_reminder_job.rb`, `app/services/payment_reminder_service.rb` |
| Estimate System | ✅ Done | Full controller, model, views |
| Owner Analytics | ✅ Done | MRR, customer analytics, payment health |
| Alerts System | ✅ Done | `app/models/alert.rb`, `app/services/alert_service.rb` |

---

## Tier 1 Features (Detailed)

### 1. Estimate PDF & Email ✅ COMPLETE
**Branch**: `feature/estimate-pdf-email` | **PR**: #54

**What was implemented**:
- EstimateMailer with HTML/text templates
- EstimatePdfGenerator service using Prawn
- Send estimate action in controller
- Professional PDF layout matching invoice style

**Files created**:
- `app/mailers/estimate_mailer.rb`
- `app/views/estimate_mailer/send_estimate.html.erb`
- `app/views/estimate_mailer/send_estimate.text.erb`
- `app/services/pdf/estimate_pdf_generator.rb`
- `spec/mailers/estimate_mailer_spec.rb`
- `spec/services/pdf/estimate_pdf_generator_spec.rb`

---

### 2. User Onboarding Checklist ✅ COMPLETE
**Branch**: `feature/onboarding-checklist` | **PR**: #55

**What was implemented**:
- OnboardingProgress model tracking 4 steps per user
- OnboardingTrackable concern for automatic step tracking
- Dismissible checklist UI with progress visualization
- Stimulus controller for smooth animations

**Steps tracked**:
1. `created_client` - When user creates their first client
2. `created_project` - When user creates their first project
3. `created_invoice` - When user creates their first invoice
4. `sent_invoice` - When user sends their first invoice

**Files created**:
- `db/migrate/20251210111234_create_onboarding_progresses.rb`
- `app/models/onboarding_progress.rb`
- `app/controllers/concerns/onboarding_trackable.rb`
- `app/controllers/onboarding_controller.rb`
- `app/views/shared/_onboarding_checklist.html.erb`
- `app/javascript/controllers/onboarding_controller.js`
- `spec/models/onboarding_progress_spec.rb`
- `spec/requests/onboarding_spec.rb`

---

### 3. Client Portal - Token-Based (6-8 hrs)
**Branch**: `feature/client-portal` | **Status**: Not started

**Decision**: Token-based access (no login required for clients)

**Features to implement**:
- Secure token generation per client
- View invoices and estimates
- Download PDFs
- Make payments via existing Stripe flow
- View project status

**Planned files**:
- `db/migrate/xxx_add_portal_token_to_clients.rb`
- `app/controllers/portal_controller.rb`
- `app/views/portal/` (dashboard, invoices, estimates, projects)
- Routes: `GET /portal/:token`

**Implementation steps**:
```bash
# Migration
rails g migration AddPortalTokenToClients portal_token:string:uniq

# Tests first (TDD)
spec/requests/portal_spec.rb
spec/system/portal_spec.rb

# Implementation
app/controllers/portal_controller.rb
app/views/portal/
```

---

### 4. Bulk Invoice from Time/Materials (3-4 hrs)
**Branch**: `feature/bulk-invoice` | **Status**: Not started

**Features to implement**:
- Select multiple uninvoiced time entries
- Select multiple uninvoiced material entries
- Auto-generate line items from selections
- Preview before creation

**Planned files**:
- `app/services/bulk_invoice_generator.rb`
- `app/views/invoices/_bulk_select.html.erb`
- `app/javascript/controllers/bulk_select_controller.js`

**Implementation steps**:
```bash
# Tests first (TDD)
spec/services/bulk_invoice_generator_spec.rb
spec/requests/invoices_spec.rb (bulk actions)

# Implementation
app/services/bulk_invoice_generator.rb
```

---

## Quick Fixes (Can be done alongside features)

| Fix | File | Effort | Status |
|-----|------|--------|--------|
| Rate Limiting config | `config/initializers/rack_attack.rb` | 30 min | 🔲 |
| API Token Refresh | `app/controllers/api/v1/authentication_controller.rb` | 1 hr | 🔲 |
| OAuth Callbacks | `app/controllers/oauth_callbacks_controller.rb` | 1 hr | 🔲 |

---

## Estimated Remaining Effort

| Feature | Hours | Status |
|---------|-------|--------|
| ~~Estimate PDF & Email~~ | ~~2-3~~ | ✅ Complete |
| ~~User Onboarding~~ | ~~4-6~~ | ✅ Complete |
| Client Portal | 6-8 | 🔲 Ready to start |
| Bulk Invoice | 3-4 | 🔲 Ready to start |
| Quick Fixes | 2-3 | 🔲 Ready to start |
| **Total Remaining** | **11-15 hrs** | |

---

## Development Workflow

**ALWAYS follow TDD pattern**:
1. Create new branch: `git checkout -b feature/feature-name`
2. Write failing tests first (Red)
3. Implement feature (Green)
4. Refactor if needed
5. Ensure all tests pass: `bundle exec rspec`
6. Commit with descriptive message
7. Push and create PR: `git push -u origin feature/feature-name`

---

## Next Action

Start with **Client Portal** feature:
1. Create branch `feature/client-portal`
2. Write tests (TDD)
3. Implement portal controller and views
4. Test, commit, push, PR
