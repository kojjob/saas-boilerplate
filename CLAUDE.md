# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Subcontractor Command** - A vertical SaaS platform for subcontractors in skilled trades (plumbers, electricians, HVAC, etc.) built with Ruby on Rails 8.

**Core Features:**
- Invoice creation & tracking with payment status
- Project management dashboard
- Client communication hub (SMS, email, in-app)
- Document storage (contracts, photos, receipts)
- Time & materials logging

**Tech Stack:**
- Rails 8.0+ with Ruby 3.3+
- PostgreSQL 16+
- Hotwire (Turbo + Stimulus)
- Tailwind CSS 4.0
- AWS S3 for file storage
- Solid Queue (background jobs)
- Solid Cable (WebSockets)
- Kamal 2.0 for deployment

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
rails generate model Client user:references name:string email:string
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
    record.user == user && !record.paid?
  end

  def destroy?
    record.user == user && record.draft?
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
```

## Core Models & Associations

```ruby
User
├── has_many :clients
├── has_many :projects
├── has_many :invoices
├── has_many :messages
├── has_many :documents
├── has_many :time_entries
└── has_many :material_entries

Client
├── belongs_to :user
├── has_many :projects
├── has_many :invoices
└── has_many :messages

Project
├── belongs_to :user
├── belongs_to :client
├── has_many :invoices
├── has_many :messages
├── has_many :documents
├── has_many :time_entries
└── has_many :material_entries

Invoice
├── belongs_to :user
├── belongs_to :client
├── belongs_to :project (optional)
└── has_many :line_items
```

**Key Model Methods:**
```ruby
# Invoice
invoice.mark_as_paid!(payment_date:, payment_method:)
invoice.days_overdue  # Returns integer
invoice.calculate_totals  # Before save callback

# Project
project.total_time_cost
project.total_materials_cost
project.total_project_cost
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
├── controllers/         # Request specs
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
    association :user
    association :client
    invoice_number { Faker::Number.unique.number(digits: 5).to_s }
    status { :draft }
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

    message = "Reminder: Invoice ##{invoice.invoice_number} for $#{invoice.total_amount} is due on #{invoice.due_date.strftime('%m/%d/%Y')}."

    SmsSender.new(
      to: invoice.client.phone_number,
      body: message
    ).send
  end
end

# Enqueue job
InvoiceReminderJob.perform_later(@invoice)
```

## Code Quality Standards

1. **Test-Driven Development**: Write tests before implementation
2. **Rails Conventions**: Follow RESTful routes, MVC pattern, ActiveRecord associations
3. **Mobile-First**: Use Tailwind responsive classes, optimize for touch
4. **Security**: Always use Pundit for authorization, sanitize inputs, strong parameters
5. **Performance**: Use database indexes, implement caching, avoid N+1 queries
6. **Simplicity**: Target users have low tech savvy - keep UI intuitive and fast

## Common Patterns

### Avoid N+1 Queries
```ruby
# Bad - N+1 queries
@invoices = Invoice.all
@invoices.each { |i| puts i.client.name }

# Good - Single query
@invoices = Invoice.includes(:client).all
@invoices.each { |i| puts i.client.name }
```

### Proper Error Handling
```ruby
def create
  @invoice = current_user.invoices.build(invoice_params)

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

# Usage
Invoice.unpaid.overdue.count
```

## Project-Specific Notes

- **Target Users**: Solo subcontractors with low-moderate tech skills
- **Priority**: Simplicity and speed over advanced features
- **UUID Primary Keys**: All tables use UUIDs instead of integers
- **File Storage**: AWS S3 for documents/receipts (25MB max per file)
- **SMS Integration**: Twilio for client communications
- **Payment Terms**: Default "Net 30", customizable per invoice
- **Invoice Numbering**: Auto-generated sequential (e.g., 10001, 10002)

See TradeDesk/CLAUDE.md and TradeDesk/PRD.md for comprehensive architecture details and product requirements.
