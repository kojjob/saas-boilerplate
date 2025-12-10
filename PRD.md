# SoloBiz - Product Requirements Document

## Executive Summary

**SoloBiz** is an all-in-one invoicing, accounting, and project tracking platform designed specifically for freelancers and small business owners. Built to replace the frustrating experience of juggling 3+ separate tools, SoloBiz provides a unified solution that handles everything from client management to year-end tax preparation.

---

## Market Opportunity

### Target Market

**Primary Audience:** Freelancers and solopreneurs earning $2,000 - $20,000/month

**Demographics:**
- Solo consultants, designers, developers, writers, marketers
- Small agency owners (1-5 employees)
- Independent contractors across all industries
- Side-hustlers growing into full-time businesses

**Psychographics:**
- Frustrated with using multiple disconnected tools
- Value simplicity over feature complexity
- Time-poor, need solutions that "just work"
- Willing to pay for tools that save time and reduce stress
- Often handle their own bookkeeping and invoicing

### Pain Points We Solve

| Pain Point | Current Reality | SoloBiz Solution |
|------------|-----------------|------------------|
| **Tool Fragmentation** | Using 3-5 separate apps (invoicing, time tracking, expenses, accounting) | Single unified platform |
| **Manual Data Entry** | Re-entering data across multiple systems | Automatic data flow between features |
| **Tax Season Chaos** | Scrambling to find receipts and organize records | One-click accountant export |
| **Cash Flow Blindness** | No clear picture of money coming in/out | Real-time financial dashboard |
| **Unprofessional Invoices** | Generic templates that don't inspire confidence | Beautiful, customizable invoices |
| **Payment Chasing** | Manual follow-ups on overdue invoices | Automated payment reminders |

### Competitive Landscape

| Competitor | Strengths | Weaknesses | Our Differentiation |
|------------|-----------|------------|---------------------|
| **FreshBooks** | Established brand, polished UI | Expensive ($17-55/mo), bloated features | Simpler, more affordable, freelancer-focused |
| **Wave** | Free invoicing | Limited features, ads, slow support | No ads, faster, better UX |
| **QuickBooks Self-Employed** | Tax integration | Confusing UI, overkill for most | Intuitive design, right-sized features |
| **Bonsai** | Contracts + invoicing | $24-79/mo, contract-heavy | Better invoicing, lower price |
| **Honeybook** | Beautiful design | $19-79/mo, event-focused | Industry-agnostic, simpler pricing |

---

## Product Vision

### Mission Statement

> **Empower freelancers to focus on their craft, not their paperwork.**

### Core Value Propositions

1. **One Tool, Zero Hassle** - Everything you need to run your freelance business in one place
2. **Get Paid Faster** - Professional invoices with online payments and automated reminders
3. **Tax Season Ready** - Organized records and one-click accountant exports
4. **Know Your Numbers** - Clear financial dashboard showing exactly where you stand

### Product Principles

- **Simplicity First:** If a feature requires explanation, it's too complex
- **Mobile-Ready:** Freelancers work from anywhere
- **Fast by Default:** Every page loads in under 2 seconds
- **Privacy Respected:** Your data is yours; we never sell it
- **Delightful Details:** Small touches that make daily use enjoyable

---

## Business Model

### Pricing Strategy

| Plan | Price | Target User | Key Features |
|------|-------|-------------|--------------|
| **Starter** | $29/month | New freelancers, side-hustlers | 5 clients, 20 invoices/mo, basic reports |
| **Professional** | $49/month | Full-time freelancers | Unlimited clients/invoices, recurring invoices, expense tracking |
| **Business** | $79/month | Growing agencies, power users | Multi-currency, team access, API, priority support |

**Annual Discount:** 20% off (2 months free)

### Revenue Projections

| Milestone | Customers | MRR | Timeline |
|-----------|-----------|-----|----------|
| Launch | 50 | $2,000 | Month 1-2 |
| Traction | 100 | $5,000 | Month 3-6 |
| Growth | 250 | $12,500 | Month 6-12 |
| Scale | 500 | $25,000 | Year 2 |

### Unit Economics

- **Customer Acquisition Cost (CAC):** Target $50-100
- **Lifetime Value (LTV):** Target $600+ (12+ month retention)
- **LTV:CAC Ratio:** Target 6:1 or better
- **Gross Margin:** Target 80%+

---

## Feature Specifications

### Phase 1: Core Platform (MVP)

#### 1.1 Client Management

**User Stories:**
- As a freelancer, I want to store client contact information so I can quickly create invoices
- As a freelancer, I want to see all projects and invoices for a client in one place
- As a freelancer, I want to track client communication history

**Features:**
- Client profiles with contact information
- Company and individual client support
- Client-specific notes and tags
- Client portal for invoice viewing/payment
- Activity history per client

**Data Model:**
```
Client
├── name (required)
├── email (required, unique per account)
├── company
├── phone
├── address (line1, line2, city, state, postal_code, country)
├── preferred_currency
├── payment_terms (default: Net 30)
├── notes
├── tags[]
├── status (active, archived)
└── portal_token (for client portal access)
```

#### 1.2 Invoice Management

**User Stories:**
- As a freelancer, I want to create professional invoices in under 2 minutes
- As a freelancer, I want to track which invoices are paid, pending, or overdue
- As a freelancer, I want clients to pay online via credit card or bank transfer
- As a freelancer, I want automatic payment reminders sent to clients

**Features:**
- Clean, professional invoice templates
- Line items with descriptions, quantities, rates
- Tax calculation (percentage or fixed)
- Discount support (percentage or fixed)
- Multiple currency support (USD, EUR, GBP, CAD, AUD, etc.)
- PDF generation and download
- Email delivery with tracking (opened, viewed)
- Online payment via Stripe
- Payment status tracking (draft, sent, viewed, paid, overdue)
- Automatic overdue detection
- Payment reminder automation (configurable schedule)
- Partial payment support
- Invoice duplication for recurring work

**Data Model:**
```
Invoice
├── invoice_number (auto-generated, e.g., INV-10001)
├── client_id (required)
├── project_id (optional)
├── status (draft, sent, viewed, paid, overdue, cancelled)
├── currency (default: USD)
├── issue_date
├── due_date
├── line_items[]
│   ├── description
│   ├── quantity
│   ├── unit_price
│   └── amount
├── subtotal
├── tax_rate
├── tax_amount
├── discount_amount
├── total_amount
├── notes (displayed on invoice)
├── terms (payment terms text)
├── sent_at
├── viewed_at
├── paid_at
├── payment_method
├── payment_reference
└── payment_token (for secure payment links)
```

#### 1.3 Project Tracking

**User Stories:**
- As a freelancer, I want to organize work by project
- As a freelancer, I want to track time spent on projects
- As a freelancer, I want to see project profitability

**Features:**
- Project creation with client association
- Project status workflow (active, on_hold, completed, cancelled)
- Time entry logging
- Project-based invoicing
- Budget tracking (optional)
- Project notes and files

**Data Model:**
```
Project
├── name (required)
├── client_id (required)
├── description
├── status (active, on_hold, completed, cancelled)
├── start_date
├── end_date
├── budget_amount
├── hourly_rate
└── notes

TimeEntry
├── project_id (required)
├── description
├── duration_minutes
├── hourly_rate
├── billable (boolean)
├── date
└── invoiced (boolean)
```

#### 1.4 Financial Dashboard

**User Stories:**
- As a freelancer, I want to see my income at a glance
- As a freelancer, I want to know how much money is outstanding
- As a freelancer, I want to track my monthly/yearly revenue trends

**Features:**
- Revenue summary (this month, this quarter, this year)
- Outstanding invoices amount and count
- Overdue invoices alert
- Recent activity feed
- Top clients by revenue
- Monthly revenue chart
- Cash flow projection (based on due dates)

### Phase 2: Financial Tools

#### 2.1 Expense Tracking

**User Stories:**
- As a freelancer, I want to track business expenses for tax purposes
- As a freelancer, I want to photograph receipts on my phone
- As a freelancer, I want to categorize expenses automatically

**Features:**
- Expense entry with receipt upload
- Mobile receipt capture (photo)
- Expense categories (software, hardware, travel, meals, office, etc.)
- Vendor tracking
- Billable expense marking (for client reimbursement)
- Expense-to-invoice linking
- Recurring expense tracking
- CSV import for bank statements

**Data Model:**
```
Expense
├── description (required)
├── amount (required)
├── currency
├── category (enum)
├── vendor
├── expense_date (required)
├── client_id (optional, for billable expenses)
├── project_id (optional)
├── receipt (file attachment)
├── billable (boolean)
├── reimbursable (boolean)
├── invoiced (boolean)
└── notes
```

**Categories:**
- Software & Subscriptions
- Hardware & Equipment
- Travel & Transportation
- Meals & Entertainment
- Office Supplies
- Professional Services
- Marketing & Advertising
- Utilities & Internet
- Insurance
- Education & Training
- Other

#### 2.2 Recurring Invoices

**User Stories:**
- As a freelancer, I want to automatically send invoices for retainer clients
- As a freelancer, I want to set up monthly/weekly/quarterly billing schedules
- As a freelancer, I want to pause and resume recurring invoices

**Features:**
- Recurring invoice templates
- Flexible scheduling (weekly, bi-weekly, monthly, quarterly, annually)
- Automatic invoice generation and sending
- Pause/resume functionality
- Email notification when generated
- End date or occurrence limit
- Draft mode (generate but don't send automatically)

**Data Model:**
```
RecurringInvoice
├── client_id (required)
├── project_id (optional)
├── frequency (weekly, biweekly, monthly, quarterly, annually)
├── status (active, paused, cancelled)
├── next_run_date
├── end_date (optional)
├── occurrences_limit (optional)
├── occurrences_count
├── auto_send (boolean)
├── line_items[] (same as Invoice)
├── tax_rate
├── discount_amount
├── notes
└── terms
```

#### 2.3 Estimates & Quotes

**User Stories:**
- As a freelancer, I want to send professional quotes to potential clients
- As a freelancer, I want to convert accepted quotes to invoices
- As a freelancer, I want to track quote acceptance rates

**Features:**
- Estimate creation (similar to invoices)
- Estimate status (draft, sent, viewed, accepted, declined, expired)
- Client acceptance workflow
- One-click conversion to invoice
- Expiration dates
- Version history
- E-signature support (future)

### Phase 3: Advanced Features

#### 3.1 Accountant Export

**User Stories:**
- As a freelancer, I want to export all financial data for my accountant
- As a freelancer, I want year-end reports ready for tax filing
- As a freelancer, I want to download all receipts in one zip file

**Features:**
- Year-end export bundle containing:
  - Invoices CSV (all invoice data)
  - Expenses CSV (all expense data)
  - Payments CSV (payment records)
  - Profit & Loss summary PDF
  - All invoice PDFs
  - All expense receipts
- QuickBooks-compatible CSV format
- Date range selection
- Categorized exports

#### 3.2 Reports & Analytics

**User Stories:**
- As a freelancer, I want to see my profit and loss statement
- As a freelancer, I want to track expenses by category
- As a freelancer, I want to see which clients generate the most revenue

**Reports:**
- Profit & Loss (Income - Expenses)
- Invoice Aging (Outstanding by age bucket: 0-30, 31-60, 61-90, 90+)
- Revenue by Client
- Revenue by Month/Quarter/Year
- Expense by Category
- Tax Summary (estimated quarterly taxes)
- Time by Project
- Billable vs Non-billable Time

#### 3.3 Multi-Currency Support

**User Stories:**
- As a freelancer working with international clients, I want to invoice in their preferred currency
- As a freelancer, I want to set default currencies per client
- As a freelancer, I want to see reports in my home currency

**Features:**
- 19 supported currencies (USD, EUR, GBP, CAD, AUD, NZD, CHF, JPY, CNY, INR, BRL, MXN, SGD, HKD, SEK, NOK, DKK, PLN, ZAR)
- Client-level currency preference
- Account-level default currency
- Currency symbols and formatting
- Exchange rate tracking for reporting (future)

#### 3.4 Team Features (Business Plan)

**User Stories:**
- As an agency owner, I want to invite team members to help manage clients
- As an agency owner, I want to control what each team member can access
- As an agency owner, I want to see activity across my team

**Features:**
- Team member invitations
- Role-based permissions (owner, admin, member, viewer)
- Activity audit log
- Per-user time tracking
- Team performance dashboard

---

## Technical Architecture

### Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Backend** | Ruby on Rails 8.0 | Rapid development, convention over configuration |
| **Database** | PostgreSQL 16 | Robust, scalable, great for financial data |
| **Frontend** | Hotwire (Turbo + Stimulus) | Fast, modern UX without heavy JavaScript |
| **Styling** | Tailwind CSS 4.0 | Utility-first, highly customizable |
| **Background Jobs** | Solid Queue | Native Rails 8, no Redis dependency |
| **WebSockets** | Solid Cable | Real-time updates, native Rails 8 |
| **File Storage** | AWS S3 | Scalable, reliable, cost-effective |
| **Email** | AWS SES | High deliverability, cost-effective |
| **Payments** | Stripe | Industry standard, great DX |
| **Deployment** | Kamal 2.0 | Zero-downtime, container-based |
| **Hosting** | Hetzner/AWS | Cost-effective scaling |

### Security Requirements

- **Data Encryption:** All data encrypted at rest and in transit (TLS 1.3)
- **Authentication:** Secure password hashing (bcrypt), optional 2FA
- **Authorization:** Role-based access control via Pundit
- **Payment Security:** PCI-DSS compliance via Stripe (no card data stored)
- **File Security:** Signed URLs for document access, virus scanning
- **Audit Logging:** All financial operations logged with timestamps
- **GDPR Compliance:** Data export, deletion on request

### Performance Requirements

- **Page Load:** < 2 seconds for all pages
- **API Response:** < 500ms for all endpoints
- **PDF Generation:** < 5 seconds per invoice
- **File Upload:** Support up to 25MB per file
- **Uptime:** 99.9% availability target
- **Database:** Support 10,000+ invoices per account

### Scalability Considerations

- **Multi-tenant Architecture:** Account-based data isolation
- **Database Sharding:** Prepared for future horizontal scaling
- **CDN:** Static assets served via CloudFront
- **Caching:** Page and fragment caching for dashboard
- **Background Processing:** Async for emails, PDFs, exports

---

## User Experience

### Design Principles

1. **Clarity Over Cleverness:** Every element has a clear purpose
2. **Progressive Disclosure:** Show basics first, details on demand
3. **Consistent Patterns:** Same interactions work the same way everywhere
4. **Helpful Defaults:** Smart defaults reduce decisions
5. **Forgiving Design:** Easy to undo, hard to make mistakes
6. **Accessible:** WCAG 2.1 AA compliance

### Key User Flows

#### Creating an Invoice (Target: < 2 minutes)

```
1. Click "New Invoice" button
2. Select client (or create new)
3. Add line items (description, qty, rate)
4. Review auto-calculated totals
5. Click "Send Invoice"
6. Confirm email delivery
```

#### Recording an Expense (Target: < 1 minute)

```
1. Click "New Expense" or use mobile quick-add
2. Enter amount and description
3. Select category (smart suggestions)
4. Upload receipt photo (optional)
5. Save
```

#### Client Payment Flow

```
1. Client receives invoice email
2. Clicks "View Invoice" button
3. Reviews invoice details on branded page
4. Clicks "Pay Now"
5. Enters payment details (Stripe)
6. Receives confirmation
7. Freelancer notified of payment
```

### Mobile Experience

- **Responsive Design:** Full functionality on mobile
- **Touch-Optimized:** Large tap targets, swipe actions
- **Quick Actions:** Fast expense entry, invoice status checks
- **Offline Capable:** Receipt photos queued for upload
- **PWA Support:** Install as app on home screen (future)

---

## Go-to-Market Strategy

### Launch Strategy

**Phase 1: Private Beta (Month 1-2)**
- Invite 50 freelancers from personal network
- Gather feedback, fix bugs, iterate
- Focus on core invoicing flow

**Phase 2: Public Beta (Month 2-3)**
- Open waitlist
- Launch on ProductHunt
- Content marketing kickoff
- Offer founding member pricing (30% off forever)

**Phase 3: General Availability (Month 3+)**
- Full public launch
- Paid advertising begins
- Partnership outreach
- Referral program activation

### Marketing Channels

| Channel | Strategy | Target CAC |
|---------|----------|------------|
| **Content/SEO** | Blog posts on freelance finances, invoice templates | $20 |
| **ProductHunt** | Launch + ongoing engagement | $10 |
| **Twitter/X** | Indie hacker community, freelancer tips | $30 |
| **LinkedIn** | Professional freelancer audience | $50 |
| **Referrals** | $20 credit for referrer and referee | $40 |
| **Partnerships** | Integrate with freelancer communities, tools | $25 |
| **Paid Ads** | Google (invoice software), Facebook (freelancers) | $80 |

### Content Strategy

**Blog Topics:**
- "How to Write an Invoice That Gets Paid"
- "Freelancer Tax Guide 2024"
- "Setting Your Freelance Rates"
- "Getting Clients to Pay on Time"
- "Expense Categories Every Freelancer Should Track"
- "When to Fire a Client (And How to Do It)"

**Resources:**
- Free invoice templates (PDF, Google Docs, Excel)
- Freelance rate calculator
- Tax deduction checklist
- Client contract templates
- Proposal templates

### Competitive Positioning

**Tagline Options:**
- "Invoicing for Freelancers. Simple."
- "One Tool for Your Freelance Business"
- "Get Paid. Track Expenses. Stay Organized."
- "The Financial Sidekick for Freelancers"

**Key Messages:**
1. **Simplicity:** "Everything you need, nothing you don't"
2. **Speed:** "Create and send invoices in 2 minutes"
3. **Affordability:** "All features for $29-79/month"
4. **All-in-One:** "Stop juggling 5 different apps"

---

## Success Metrics

### North Star Metric

**Monthly Invoiced Volume** - Total dollar amount of invoices sent through SoloBiz

*Rationale: Directly correlates with customer success and indicates platform stickiness*

### Key Performance Indicators (KPIs)

| Metric | Definition | Target |
|--------|------------|--------|
| **MRR** | Monthly recurring revenue | $5K (6 months), $25K (1 year) |
| **Active Users** | Users with activity in last 30 days | 80%+ of paying customers |
| **Invoices Sent** | Number of invoices sent per month | 5+ per active user |
| **Payment Success Rate** | % of invoices paid within 30 days | 70%+ |
| **Churn Rate** | Monthly customer churn | < 5% |
| **NPS** | Net Promoter Score | 50+ |
| **Time to Value** | Time from signup to first invoice sent | < 10 minutes |
| **Support Tickets** | Tickets per 100 customers per month | < 10 |

### Health Metrics

- **Daily Active Users (DAU):** Sign of habit formation
- **Feature Adoption:** % using expenses, recurring invoices, etc.
- **Mobile Usage:** % of actions from mobile devices
- **Email Open Rates:** Invoice delivery effectiveness
- **Payment Method Distribution:** Card vs bank transfer vs manual

---

## Roadmap

### Q1 2025: Foundation

- [x] Core platform architecture
- [x] User authentication & accounts
- [x] Client management
- [x] Basic invoice creation & management
- [x] PDF invoice generation
- [x] Email delivery
- [ ] Multi-currency support
- [ ] Stripe payment integration
- [ ] Mobile-responsive design
- [ ] Public beta launch

### Q2 2025: Financial Tools

- [ ] Expense tracking with receipt uploads
- [ ] Recurring invoices
- [ ] Financial dashboard
- [ ] Basic reports (P&L, aging)
- [ ] Automated payment reminders
- [ ] Client portal
- [ ] Time tracking basics

### Q3 2025: Growth Features

- [ ] Estimates/quotes module
- [ ] Accountant export
- [ ] Advanced reports
- [ ] Bank connection (Plaid)
- [ ] Mobile app (PWA)
- [ ] API for integrations
- [ ] Zapier integration

### Q4 2025: Scale

- [ ] Team features
- [ ] Multi-currency reporting
- [ ] E-signatures for estimates
- [ ] Advanced automation rules
- [ ] White-label options
- [ ] Partner/reseller program

---

## Appendices

### A. User Research Summary

*[To be populated with actual user research findings]*

Key insights from early user interviews:
- Pain of switching between multiple tools
- Desire for professional-looking invoices
- Tax season stress is a major motivator
- Mobile access is important but not primary
- Simplicity valued over feature count

### B. Competitive Feature Matrix

| Feature | SoloBiz | FreshBooks | Wave | QuickBooks SE | Bonsai |
|---------|---------|------------|------|---------------|--------|
| Invoicing | ✅ | ✅ | ✅ | ✅ | ✅ |
| Online Payments | ✅ | ✅ | ✅ | ✅ | ✅ |
| Expense Tracking | ✅ | ✅ | ✅ | ✅ | ✅ |
| Receipt Scanning | ✅ | ✅ | ❌ | ✅ | ❌ |
| Recurring Invoices | ✅ | ✅ | ✅ | ❌ | ✅ |
| Time Tracking | ✅ | ✅ | ❌ | ❌ | ✅ |
| Project Management | ✅ | ✅ | ❌ | ❌ | ✅ |
| Estimates/Quotes | ✅ | ✅ | ✅ | ❌ | ✅ |
| Multi-Currency | ✅ | ✅ | ✅ | ❌ | ✅ |
| Contracts | ❌ | ❌ | ❌ | ❌ | ✅ |
| Mileage Tracking | ❌ | ✅ | ❌ | ✅ | ❌ |
| Bank Connection | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Starting Price** | **$29** | $17 | Free | $15 | $24 |

### C. Technical Debt Considerations

- Plan for multi-tenant isolation from day one
- Build reporting infrastructure early
- Implement proper audit logging
- Design for eventual API exposure
- Consider webhook system for future integrations

### D. Regulatory Considerations

- GDPR compliance for EU customers
- SOC 2 Type II certification (future)
- PCI-DSS compliance via Stripe
- Data retention policies
- Right to deletion implementation

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2024 | Product Team | Initial PRD |

---

*This is a living document. Last updated: December 2024*
