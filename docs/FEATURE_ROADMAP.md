# Feature Recommendations for Subcontractor Command

## Executive Summary

Based on comprehensive analysis of the codebase, competitor landscape, and technical capabilities, this document outlines recommended features prioritized by business impact and implementation feasibility.

**Current State**: ~60% feature-complete vs. competitors (Jobber, ServiceTitan, Housecall Pro)
**Target User**: Solo subcontractors in skilled trades with low-moderate tech skills

---

## TIER 1: CRITICAL FEATURES (Revenue & Core Functionality)

### 1. Online Payment Processing via Stripe
**Priority**: 🔴 HIGHEST
**Effort**: 1-2 weeks
**Business Impact**: 5-10% revenue increase through faster cash flow

**Why**: Currently only manual payment tracking exists. Subcontractors need to collect payments online.

**Implementation**:
- Add Stripe payment links to invoices
- Client-facing payment page (no login required)
- Payment status webhooks to auto-mark invoices as paid
- Receipt generation and email delivery

**Files to Create/Modify**:
- `app/controllers/invoice_payments_controller.rb`
- `app/views/invoices/_payment_button.html.erb`
- `app/views/invoice_payments/new.html.erb` (public payment page)
- `config/routes.rb` - public payment routes

---

### 2. Estimates/Quotes Module
**Priority**: 🔴 HIGH
**Effort**: 2-3 weeks
**Business Impact**: Captures 30-50% of workflow currently done outside app

**Why**: Subcontractors spend significant time creating estimates before work begins. No estimate system means lost opportunity.

**Implementation**:
- New Estimate model (similar to Invoice structure)
- Estimate templates (copy from previous quotes)
- Quote-to-Project conversion workflow
- Client approval tracking (sent, viewed, accepted, declined)
- Estimate expiration dates

**Files to Create**:
- `app/models/estimate.rb`
- `app/models/estimate_line_item.rb`
- `app/controllers/estimates_controller.rb`
- `app/views/estimates/*`
- `db/migrate/create_estimates.rb`

---

### 3. PDF Invoice Generation & Email Delivery
**Priority**: 🔴 HIGH
**Effort**: 1 week
**Business Impact**: Professional appearance, client convenience

**Why**: Currently no way to send professional PDF invoices to clients.

**Implementation**:
- Add `prawn` or `wicked_pdf` gem for PDF generation
- Invoice PDF template with branding
- Email delivery with PDF attachment
- Download PDF button on invoice show page

**Files to Create/Modify**:
- `app/services/invoice_pdf_generator.rb`
- `app/mailers/invoice_mailer.rb`
- `app/views/invoice_mailer/send_invoice.html.erb`
- `app/views/invoices/show.pdf.erb`

---

### 4. Invoice Payment Reminders (Automated)
**Priority**: 🟠 HIGH
**Effort**: 1 week
**Business Impact**: Faster collection, improved cash flow

**Why**: Manual follow-up on overdue invoices is time-consuming. Automation helps.

**Implementation**:
- Recurring job to check overdue invoices
- Email reminder templates (3 days before due, on due date, 7 days overdue)
- SMS reminder option (Twilio integration)
- Reminder history tracking

**Files to Create**:
- `app/jobs/invoice_reminder_job.rb`
- `app/mailers/invoice_reminder_mailer.rb`
- `config/recurring.yml` - add reminder schedule

---

## TIER 2: HIGH-VALUE FEATURES (Growth & Retention)

### 5. Client Portal (Public Access)
**Priority**: 🟠 MEDIUM-HIGH
**Effort**: 2-3 weeks
**Business Impact**: Reduces support burden, enables self-service

**Why**: Clients need to view invoices, project status, and pay without calling the subcontractor.

**Implementation**:
- Public-facing client dashboard (token-based access)
- Invoice history and payment status
- Project progress viewing
- Document downloads (contracts, receipts)
- Self-service payment

**Files to Create**:
- `app/controllers/client_portal_controller.rb`
- `app/views/client_portal/*`
- `app/models/client_access_token.rb`

---

### 6. Calendar/Scheduling View
**Priority**: 🟠 MEDIUM
**Effort**: 2 weeks
**Business Impact**: Operational efficiency, prevents double-booking

**Why**: Projects have dates but no visual calendar. Subcontractors need to see their schedule at a glance.

**Implementation**:
- Calendar view of projects/jobs
- Drag-and-drop scheduling
- Conflict detection
- Daily/weekly/monthly views
- Mobile-optimized calendar

**Files to Create**:
- `app/javascript/controllers/calendar_controller.js`
- `app/views/calendar/index.html.erb`
- `app/controllers/calendar_controller.rb`

---

### 7. Recurring Invoices
**Priority**: 🟠 MEDIUM
**Effort**: 1 week
**Business Impact**: 15-20% recurring revenue for maintenance contracts

**Why**: Many subcontractors have recurring work (monthly maintenance, seasonal services).

**Implementation**:
- Mark invoice as recurring (monthly, quarterly, yearly)
- Auto-generate invoices on schedule
- Recurring invoice management UI

**Files to Modify/Create**:
- `app/models/invoice.rb` - add recurring fields
- `app/jobs/generate_recurring_invoices_job.rb`
- `db/migrate/add_recurring_to_invoices.rb`

---

### 8. SMS Notifications (Twilio)
**Priority**: 🟠 MEDIUM
**Effort**: 1-2 weeks
**Business Impact**: Higher open rates than email, faster communication

**Why**: SMS has 98% open rate vs 20% for email. Critical for time-sensitive notifications.

**Implementation**:
- Twilio integration for outbound SMS
- Invoice sent/due/paid notifications
- Appointment reminders
- Client SMS preferences

**Files to Create**:
- `app/services/sms_sender.rb`
- `app/jobs/send_sms_job.rb`
- Configuration for Twilio credentials

---

## TIER 3: DIFFERENTIATION FEATURES (Competitive Advantage)

### 9. Mobile-First Progressive Web App (PWA)
**Priority**: 🟡 MEDIUM
**Effort**: 2-3 weeks
**Business Impact**: Critical for field workers at job sites

**Why**: Subcontractors work at job sites, not offices. Mobile-first is essential.

**Implementation**:
- Service worker for offline capability
- App manifest for "Add to Home Screen"
- Mobile-optimized views for key actions
- Offline data sync queue

**Files to Create**:
- `app/javascript/service_worker.js`
- `public/manifest.json`
- Mobile-specific view variants

---

### 10. Photo Documentation with Metadata
**Priority**: 🟡 MEDIUM
**Effort**: 1-2 weeks
**Business Impact**: Proof of work, dispute resolution

**Why**: Before/after photos are essential for subcontractors to document work.

**Implementation**:
- Enhanced photo upload with GPS location capture
- Before/after photo pairing
- Photo galleries on projects
- Timestamp watermarks

**Files to Modify**:
- `app/models/document.rb` - add photo metadata fields
- `app/controllers/documents_controller.rb`
- `app/views/documents/*`

---

### 11. Expense Tracking & Reporting
**Priority**: 🟡 MEDIUM
**Effort**: 2 weeks
**Business Impact**: Tax preparation, profitability analysis

**Why**: Subcontractors need to track business expenses for taxes.

**Implementation**:
- Expense entry with categories (fuel, tools, materials)
- Receipt photo attachment
- Expense reports by date range
- Tax category tagging

**Files to Create**:
- `app/models/expense.rb`
- `app/controllers/expenses_controller.rb`
- `app/views/expenses/*`
- `app/views/reports/expenses.html.erb`

---

### 12. Reporting Dashboard with Charts
**Priority**: 🟡 MEDIUM
**Effort**: 2 weeks
**Business Impact**: Business insights, decision making

**Why**: Data exists but no visualization. Subcontractors need to see revenue trends.

**Implementation**:
- Revenue by month/quarter chart
- Outstanding invoices summary
- Project profitability analysis
- Client revenue breakdown
- Use Chartkick + Chart.js

**Files to Create**:
- `app/controllers/reports_controller.rb`
- `app/views/reports/dashboard.html.erb`
- Add `chartkick` gem

---

## TIER 4: SCALING FEATURES (Future Growth)

### 13. Crew/Team Management
- Job assignment to team members
- Crew scheduling
- Time tracking per crew member
- Performance metrics

### 14. QuickBooks Integration
- Export invoices to QuickBooks
- Sync customers/vendors
- Automated reconciliation

### 15. Supplier Price Lookup
- Home Depot/Lowe's API integration
- Material price comparison
- Supplier-based margin optimization

---

## QUICK WINS (High Impact, Low Effort)

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| PDF Invoice Download | 3 days | High | Do First |
| Invoice Email Delivery | 2 days | High | Do First |
| Stripe Payment Links | 1 week | Very High | Do First |
| Recurring Invoice Toggle | 3 days | Medium | Quick Win |
| Budget Overage Alerts | 2 days | Medium | Quick Win |
| AWS S3 Configuration | 1 day | Medium | Infrastructure |
| SMTP Email Setup | 1 day | High | Infrastructure |

---

## RECOMMENDED IMPLEMENTATION ORDER

### Phase 1 (Weeks 1-3): Revenue & Communication
1. Stripe payment links on invoices
2. PDF invoice generation
3. Invoice email delivery
4. AWS S3 configuration for production

### Phase 2 (Weeks 4-6): Estimates & Automation
1. Estimates/Quotes module
2. Quote-to-project conversion
3. Invoice payment reminders (automated)
4. SMS notifications (Twilio)

### Phase 3 (Weeks 7-9): Client Experience
1. Client portal (public access)
2. Recurring invoices
3. Calendar/scheduling view

### Phase 4 (Weeks 10-12): Analytics & Mobile
1. Reporting dashboard with charts
2. PWA mobile optimization
3. Photo documentation enhancements

---

## TECHNICAL DEPENDENCIES

**Gems to Add**:
- `prawn` or `wicked_pdf` - PDF generation
- `twilio-ruby` - SMS integration
- `chartkick` + `groupdate` - Charts and reporting
- `serviceworker-rails` - PWA support

**Configuration Needed**:
- AWS S3 credentials (storage.yml)
- SMTP settings (production email)
- Twilio credentials (SMS)
- Stripe webhook for payments

---

## COMPETITIVE POSITIONING

**Your Advantage**: Simplicity for solo subcontractors
- 15-minute setup vs hours for competitors
- No feature bloat (enterprise complexity)
- Mobile-first design
- $19-29/mo vs $50-300/mo competitors

**Target**: Capture the underserved solo subcontractor market that finds Jobber/ServiceTitan too complex and expensive.
