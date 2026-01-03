# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SoloBiz** - An all-in-one invoicing, accounting, and project tracking platform for freelancers and small business owners, built with Ruby on Rails 8.

**Target Market:** Freelancers earning $2k-20k/month who are frustrated with using 3+ separate tools

**Core Features:**
- Invoice creation & tracking with online payments (Stripe)
- Multi-currency support (19 currencies)
- Expense tracking with receipt photo uploads
- Recurring invoices (auto-generate on schedule)
- Project management & time tracking
- Client management with portal access
- Financial dashboard & reports
- Accountant export (year-end data bundle)

**Tech Stack:**
- Rails 8.0+ with Ruby 3.3+
- PostgreSQL 16+
- Hotwire (Turbo + Stimulus)
- Tailwind CSS 4.0
- AWS S3 for file storage
- Solid Queue (background jobs)
- Solid Cable (WebSockets)
- Kamal 2.0 for deployment

**See PRD.md for comprehensive product requirements, feature specifications, and go-to-market strategy.**

## Development Workflow

### Essential Commands

```bash
# Start development server
bin/dev

# Database operations
rails db:create
rails db:migrate
rails db:seed

# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/invoice_spec.rb

# Run specific test (line number)
bundle exec rspec spec/models/invoice_spec.rb:25

# Test coverage report
COVERAGE=true bundle exec rspec

# Rails console
bin/rails console

# Generate migration
rails generate migration AddStatusToProjects status:integer

# Generate model with tests
rails generate model Client account:references name:string email:string
```

### Git Workflow (TDD Required)

**ALWAYS follow this pattern:**
1. Create new branch for every task: `git checkout -b feature/invoice-payment-tracking`
2. Write failing tests first (Red)
3. Implement feature (Green)
4. Refactor if needed
5. Ensure all tests pass
6. Commit with descriptive message
7. Push and create PR: `git push -u origin feature/invoice-payment-tracking`

**Example:**
```bash
git checkout -b feature/mark-invoice-paid
# Write test in spec/models/invoice_spec.rb
bundle exec rspec spec/models/invoice_spec.rb  # Should fail (Red)
# Implement Invoice#mark_as_paid! method
bundle exec rspec spec/models/invoice_spec.rb  # Should pass (Green)
git add .
git commit -m "Add mark_as_paid! method to Invoice model with payment tracking"
git push -u origin feature/mark-invoice-paid
```

## Architecture Patterns

### Multi-Tenant Architecture

SoloBiz uses account-based multi-tenancy. All business data belongs to an Account, and Users access data through Memberships.

```ruby
# All business models belong to Account
class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :client
  # ...
end

# Controllers scope queries to current_account
class InvoicesController < ApplicationController
  def index
    @invoices = current_account.invoices.includes(:client)
  end
end
```

### Service Objects (Complex Business Logic)

Use for multi-step operations, external API calls, complex calculations.

```ruby
# app/services/invoice_sender.rb
class InvoiceSender
  def initialize(invoice, recipient_email)
    @invoice = invoice
    @recipient_email = recipient_email
  end

  def call
    return failure("Invoice already sent") if @invoice.sent?

    ActiveRecord::Base.transaction do
      pdf = InvoicePdfGenerator.new(@invoice).generate
      InvoiceMailer.send_invoice(@invoice, @recipient_email, pdf).deliver_later
      @invoice.update!(status: :sent, sent_at: Time.current)
    end

    success("Invoice sent successfully")
  rescue => e
    failure("Failed to send invoice: #{e.message}")
  end

  private

  def success(message)
    { success: true, message: message }
  end

  def failure(message)
    { success: false, message: message }
  end
end
```

### Shared Concerns

Common functionality is extracted into concerns for reuse across models.

```ruby
# app/models/concerns/currency_support.rb
module CurrencySupport
  extend ActiveSupport::Concern

  SUPPORTED_CURRENCIES = %w[USD EUR GBP CAD AUD NZD CHF JPY CNY INR BRL MXN SGD HKD SEK NOK DKK PLN ZAR].freeze

  class_methods do
    def validates_currency(attribute, options = {})
      validates attribute, inclusion: { in: SUPPORTED_CURRENCIES }, allow_nil: options[:allow_nil]
    end
  end

  def format_currency(amount, currency_code = nil)
    # Formats with proper symbol and thousands separator
  end
end

# Usage in models
class Invoice < ApplicationRecord
  include CurrencySupport
  validates_currency :currency
end
```

### ViewComponent (Reusable UI)

```ruby
# app/components/invoice_status_badge_component.rb
class InvoiceStatusBadgeComponent < ViewComponent::Base
  def initialize(status:)
    @status = status
  end

  def badge_class
    case @status.to_sym
    when :draft then "bg-gray-100 text-gray-800"
    when :sent then "bg-blue-100 text-blue-800"
    when :paid then "bg-green-100 text-green-800"
    when :overdue then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end
end
```

### Pundit Policies (Authorization)

```ruby
# app/policies/invoice_policy.rb
class InvoicePolicy < ApplicationPolicy
  def update?
    record.account == user.current_account && !record.paid?
  end

  def destroy?
    record.account == user.current_account && record.draft?
  end

  class Scope < Scope
    def resolve
      scope.where(account: user.current_account)
    end
  end
end
```

## Core Models & Associations

```ruby
Account
├── has_many :memberships
├── has_many :users, through: :memberships
├── has_many :clients
├── has_many :projects
├── has_many :invoices
├── has_many :expenses
├── has_many :recurring_invoices
├── has_many :documents
├── has_many :time_entries
└── default_currency (string, default: "USD")

User
├── has_many :memberships
├── has_many :accounts, through: :memberships
└── current_account (via session/context)

Client
├── belongs_to :account
├── has_many :projects
├── has_many :invoices
├── has_many :expenses
├── preferred_currency (string, optional)
└── portal_token (for client portal access)

Project
├── belongs_to :account
├── belongs_to :client
├── has_many :invoices
├── has_many :time_entries
├── has_many :expenses
└── has_many :documents

Invoice
├── belongs_to :account
├── belongs_to :client
├── belongs_to :project (optional)
├── has_many :line_items
├── currency (string, default: "USD")
└── payment_token (for secure payment links)

Expense
├── belongs_to :account
├── belongs_to :client (optional)
├── belongs_to :project (optional)
├── has_one_attached :receipt
├── category (enum)
└── billable (boolean)

RecurringInvoice
├── belongs_to :account
├── belongs_to :client
├── has_many :invoices
├── frequency (enum: weekly, biweekly, monthly, quarterly, annually)
└── status (enum: active, paused, cancelled)
```

**Key Model Methods:**
```ruby
# Invoice
invoice.mark_as_paid!(payment_date:, payment_method:)
invoice.days_overdue  # Returns integer
invoice.formatted_total  # Returns "$1,234.56"
invoice.inherit_currency_from_client!  # Sets currency from client/account

# Account
account.default_currency  # Returns "USD" or configured currency
account.within_limit?(:invoices, current_count)  # Plan limit check

# Client
client.preferred_currency  # Optional currency override
client.total_revenue  # Sum of paid invoices
client.outstanding_balance  # Sum of unpaid invoices
```

## Hotwire Best Practices

### Turbo Frames (Partial Updates)
```erb
<%= turbo_frame_tag "invoices_list" do %>
  <% @invoices.each do |invoice| %>
    <%= render partial: "invoice_card", locals: { invoice: invoice } %>
  <% end %>
<% end %>
```

### Turbo Streams (Real-time)
```ruby
# app/models/invoice.rb
after_update_commit -> { broadcast_replace_to "invoices" }
```

### Stimulus Controllers (Minimal JS)
```javascript
// app/javascript/controllers/invoice_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtotal", "tax", "total"]

  calculateTotal() {
    const subtotal = parseFloat(this.subtotalTarget.value) || 0
    const tax = parseFloat(this.taxTarget.value) || 0
    this.totalTarget.value = (subtotal + tax).toFixed(2)
  }
}
```

## Testing Strategy (RSpec)

### Test Structure
```
spec/
├── models/              # Unit tests
├── requests/            # Request/controller specs
├── system/              # End-to-end (Capybara)
├── services/            # Service object tests
├── components/          # ViewComponent tests
├── policies/            # Pundit policy tests
└── factories/           # FactoryBot factories
```

### Factory Pattern
```ruby
# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :account
    association :client
    invoice_number { "INV-#{Faker::Number.unique.number(digits: 5)}" }
    status { :draft }
    currency { "USD" }
    issue_date { Date.today }
    due_date { Date.today + 30.days }
    subtotal { 1000.00 }
    total_amount { 1000.00 }

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end

    trait :in_euros do
      currency { "EUR" }
    end
  end
end
```

### Model Test Example
```ruby
# spec/models/invoice_spec.rb
require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe '#mark_as_paid!' do
    let(:invoice) { create(:invoice, :sent) }

    it 'changes status to paid' do
      expect { invoice.mark_as_paid! }.to change { invoice.status }.to('paid')
    end

    it 'sets paid_at timestamp' do
      invoice.mark_as_paid!
      expect(invoice.paid_at).to be_present
    end
  end

  describe 'currency' do
    it 'defaults to USD' do
      invoice = build(:invoice, currency: nil)
      invoice.valid?
      expect(invoice.currency).to eq('USD')
    end

    it 'inherits from client preferred currency' do
      client = create(:client, preferred_currency: 'EUR')
      invoice = build(:invoice, client: client, currency: nil)
      invoice.valid?
      expect(invoice.currency).to eq('EUR')
    end
  end
end
```

## Deployment (Kamal 2.0)

### Common Deployment Commands
```bash
# Initial setup
kamal setup

# Deploy new version
kamal deploy

# Rollback
kamal rollback

# View logs
kamal app logs

# Rails console on server
kamal app exec -i "bin/rails console"

# Run migrations
kamal app exec "bin/rails db:migrate"
```

## Background Jobs (Solid Queue)

```ruby
# app/jobs/invoice_reminder_job.rb
class InvoiceReminderJob < ApplicationJob
  queue_as :default

  def perform(invoice)
    return unless invoice.unpaid?

    InvoiceMailer.payment_reminder(invoice).deliver_now
  end
end

# app/jobs/generate_recurring_invoices_job.rb
class GenerateRecurringInvoicesJob < ApplicationJob
  queue_as :default

  def perform
    RecurringInvoice.active.due_today.find_each do |recurring|
      RecurringInvoiceService.new(recurring).generate_invoice!
    end
  end
end

# Enqueue job
InvoiceReminderJob.perform_later(@invoice)
```

## Code Quality Standards

1. **Test-Driven Development**: Write tests before implementation (Red-Green-Refactor)
2. **Rails Conventions**: Follow RESTful routes, MVC pattern, ActiveRecord associations
3. **Mobile-First**: Use Tailwind responsive classes, optimize for touch
4. **Security**: Always use Pundit for authorization, sanitize inputs, strong parameters
5. **Performance**: Use database indexes, implement caching, avoid N+1 queries
6. **Simplicity**: Target users value ease-of-use - keep UI intuitive and fast

## Common Patterns

### Avoid N+1 Queries
```ruby
# Bad - N+1 queries
@invoices = current_account.invoices
@invoices.each { |i| puts i.client.name }

# Good - Single query
@invoices = current_account.invoices.includes(:client)
@invoices.each { |i| puts i.client.name }
```

### Proper Error Handling
```ruby
def create
  @invoice = current_account.invoices.build(invoice_params)
  @invoice.client = current_account.clients.find(params[:invoice][:client_id])

  if @invoice.save
    redirect_to @invoice, notice: 'Invoice created successfully.'
  else
    render :new, status: :unprocessable_entity
  end
end
```

### Scopes for Queries
```ruby
# app/models/invoice.rb
scope :unpaid, -> { where(status: [:sent, :viewed, :overdue]) }
scope :overdue, -> { where("due_date < ? AND status NOT IN (?)", Date.today, [:paid]) }
scope :recent, -> { order(created_at: :desc) }

# Usage
current_account.invoices.unpaid.overdue.count
```

### Currency Cascade Logic
```ruby
# Invoice currency inheritance priority:
# 1. Explicitly set currency on invoice
# 2. Client's preferred_currency (if set)
# 3. Account's default_currency
# 4. Fallback to "USD"

def set_default_currency
  return if currency.present?
  self.currency = client&.preferred_currency || account&.default_currency || "USD"
end
```

## Project-Specific Notes

- **Target Users**: Freelancers and solopreneurs ($2k-20k/month revenue)
- **Priority**: Simplicity and speed over advanced features
- **UUID Primary Keys**: All tables use UUIDs instead of integers
- **Multi-Tenant**: All data scoped to Account
- **File Storage**: AWS S3 for documents/receipts (25MB max per file)
- **Payments**: Stripe for online invoice payments
- **Payment Terms**: Default "Net 30", customizable per invoice
- **Invoice Numbering**: Auto-generated sequential (e.g., INV-10001, INV-10002)
- **Currencies**: 19 supported currencies with proper symbol formatting

## Key Files Reference

- **PRD.md**: Complete product requirements and go-to-market strategy
- **app/models/concerns/currency_support.rb**: Multi-currency formatting and validation
- **app/services/**: Business logic services (InvoiceSender, RecurringInvoiceService, etc.)
- **app/policies/**: Pundit authorization policies
- **config/routes.rb**: RESTful routing configuration
- **db/schema.rb**: Current database schema
