# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "associations" do
    it "belongs to account" do
      association = described_class.reflect_on_association(:account)
      expect(association.macro).to eq :belongs_to
    end

    it "belongs to client" do
      association = described_class.reflect_on_association(:client)
      expect(association.macro).to eq :belongs_to
    end

    it "belongs to project optionally" do
      association = described_class.reflect_on_association(:project)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:optional]).to be true
    end

    it { should have_many(:line_items).class_name("InvoiceLineItem").dependent(:destroy) }
  end

  describe "validations" do
    it "requires invoice_number" do
      invoice = create(:invoice)
      invoice.invoice_number = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:invoice_number]).to include("can't be blank")
    end

    it "requires invoice_number to be unique within account" do
      account = create(:account)
      client = create(:client, account: account)
      existing = create(:invoice, account: account, client: client)
      new_invoice = build(:invoice, account: account, client: client, invoice_number: existing.invoice_number)
      expect(new_invoice).not_to be_valid
      expect(new_invoice.errors[:invoice_number]).to include("has already been taken")
    end

    it "requires issue_date" do
      invoice = create(:invoice)
      invoice.issue_date = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:issue_date]).to include("can't be blank")
    end

    it "requires due_date" do
      invoice = create(:invoice)
      invoice.due_date = nil
      expect(invoice).not_to be_valid
      expect(invoice.errors[:due_date]).to include("can't be blank")
    end

    it "validates due_date is after issue_date" do
      invoice = build(:invoice, issue_date: Date.current, due_date: Date.current - 1.day)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:due_date]).to include("must be after issue date")
    end

    it "allows due_date equal to issue_date" do
      invoice = build(:invoice, issue_date: Date.current, due_date: Date.current)
      expect(invoice).to be_valid
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(Invoice.statuses).to eq({
        "draft" => 0,
        "sent" => 1,
        "viewed" => 2,
        "paid" => 3,
        "overdue" => 4,
        "cancelled" => 5
      })
    end
  end

  describe "callbacks" do
    it "generates invoice number on create" do
      invoice = create(:invoice)
      expect(invoice.invoice_number).to match(/^INV-\d+$/)
    end

    it "increments invoice number for same account" do
      account = create(:account)
      client = create(:client, account: account)
      invoice1 = create(:invoice, account: account, client: client)
      invoice2 = create(:invoice, account: account, client: client)

      number1 = invoice1.invoice_number.gsub(/\D/, "").to_i
      number2 = invoice2.invoice_number.gsub(/\D/, "").to_i

      expect(number2).to eq(number1 + 1)
    end

    it "sets default dates on create" do
      invoice = build(:invoice, issue_date: nil, due_date: nil)
      invoice.save!

      expect(invoice.issue_date).to eq(Date.current)
      expect(invoice.due_date).to eq(Date.current + 30.days)
    end

    it "calculates totals from line items before save" do
      invoice = create(:invoice)
      invoice.line_items.create!(description: "Service 1", quantity: 2, unit_price: 100)
      invoice.line_items.create!(description: "Service 2", quantity: 1, unit_price: 50)
      invoice.update!(tax_rate: 10)

      expect(invoice.subtotal).to eq(250)
      expect(invoice.tax_amount).to eq(25)
      expect(invoice.total_amount).to eq(275)
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:client) { create(:client, account: account) }

    describe ".with_status_paid" do
      it "returns only paid invoices" do
        paid = create(:invoice, :paid, account: account, client: client)
        draft = create(:invoice, :draft, account: account, client: client)

        expect(Invoice.with_status_paid).to include(paid)
        expect(Invoice.with_status_paid).not_to include(draft)
      end
    end

    describe ".unpaid" do
      it "returns sent, viewed, and overdue invoices" do
        sent = create(:invoice, :sent, account: account, client: client)
        viewed = create(:invoice, :viewed, account: account, client: client)
        overdue_invoice = create(:invoice, :overdue, account: account, client: client)
        draft = create(:invoice, :draft, account: account, client: client)
        paid = create(:invoice, :paid, account: account, client: client)

        unpaid = Invoice.unpaid

        expect(unpaid).to include(sent, viewed, overdue_invoice)
        expect(unpaid).not_to include(draft, paid)
      end
    end

    describe ".recent" do
      it "orders by issue_date descending" do
        old = create(:invoice, account: account, client: client, issue_date: 10.days.ago)
        recent = create(:invoice, account: account, client: client, issue_date: 1.day.ago)

        expect(Invoice.recent.first).to eq(recent)
        expect(Invoice.recent.last).to eq(old)
      end
    end

    describe ".due_soon" do
      it "returns unpaid invoices due within 7 days" do
        sent_due_soon = create(:invoice, :sent, account: account, client: client, due_date: 3.days.from_now)
        sent_due_later = create(:invoice, :sent, account: account, client: client, due_date: 14.days.from_now)
        paid_due_soon = create(:invoice, :paid, account: account, client: client, due_date: 3.days.from_now)

        due_soon = Invoice.due_soon

        expect(due_soon).to include(sent_due_soon)
        expect(due_soon).not_to include(sent_due_later, paid_due_soon)
      end
    end

    describe ".past_due" do
      it "returns unpaid invoices past due date" do
        sent_past_due = create(:invoice, :sent, account: account, client: client, issue_date: 35.days.ago, due_date: 5.days.ago)
        sent_future_due = create(:invoice, :sent, account: account, client: client, due_date: 3.days.from_now)
        paid_past_due = create(:invoice, :paid, account: account, client: client, issue_date: 35.days.ago, due_date: 5.days.ago)

        past_due = Invoice.past_due

        expect(past_due).to include(sent_past_due)
        expect(past_due).not_to include(sent_future_due, paid_past_due)
      end
    end

    describe ".search" do
      it "finds invoices by invoice_number" do
        invoice = create(:invoice, account: account, client: client)
        expect(Invoice.search(invoice.invoice_number)).to include(invoice)
      end

      it "finds invoices by client name" do
        named_client = create(:client, account: account, name: "John Smith")
        invoice = create(:invoice, account: account, client: named_client)
        expect(Invoice.search("John")).to include(invoice)
      end

      it "finds invoices by client company" do
        company_client = create(:client, account: account, company: "Acme Corporation")
        invoice = create(:invoice, account: account, client: company_client)
        expect(Invoice.search("Acme")).to include(invoice)
      end

      it "returns all when query is blank" do
        invoice = create(:invoice, account: account, client: client)
        expect(Invoice.search("")).to include(invoice)
        expect(Invoice.search(nil)).to include(invoice)
      end
    end
  end

  describe "instance methods" do
    describe "#mark_as_sent!" do
      it "changes status to sent and sets sent_at" do
        invoice = create(:invoice, :draft)
        invoice.mark_as_sent!

        expect(invoice.status).to eq("sent")
        expect(invoice.sent_at).to be_present
      end
    end

    describe "#mark_as_paid!" do
      it "changes status to paid with defaults" do
        invoice = create(:invoice, :sent)
        invoice.mark_as_paid!

        expect(invoice.status).to eq("paid")
        expect(invoice.paid_at).to be_present
      end

      it "accepts payment details" do
        invoice = create(:invoice, :sent)
        payment_date = 2.days.ago
        invoice.mark_as_paid!(
          payment_date: payment_date,
          payment_method: "credit_card",
          payment_reference: "TXN123"
        )

        expect(invoice.paid_at).to be_within(1.second).of(payment_date)
        expect(invoice.payment_method).to eq("credit_card")
        expect(invoice.payment_reference).to eq("TXN123")
      end
    end

    describe "#mark_as_overdue!" do
      it "changes status to overdue for unpaid past due invoices" do
        invoice = create(:invoice, :sent, issue_date: 35.days.ago, due_date: 5.days.ago)
        invoice.mark_as_overdue!

        expect(invoice.status).to eq("overdue")
      end

      it "does not change status for paid invoices" do
        invoice = create(:invoice, :paid, issue_date: 35.days.ago, due_date: 5.days.ago)
        invoice.mark_as_overdue!

        expect(invoice.status).to eq("paid")
      end
    end

    describe "#unpaid?" do
      it "returns true for sent, viewed, and overdue statuses" do
        expect(build(:invoice, :sent).unpaid?).to be true
        expect(build(:invoice, :viewed).unpaid?).to be true
        expect(build(:invoice, :overdue).unpaid?).to be true
      end

      it "returns false for draft, paid, and cancelled statuses" do
        expect(build(:invoice, :draft).unpaid?).to be false
        expect(build(:invoice, :paid).unpaid?).to be false
        expect(build(:invoice, :cancelled).unpaid?).to be false
      end
    end

    describe "#past_due?" do
      it "returns true when due_date is in the past" do
        invoice = build(:invoice, due_date: 1.day.ago)
        expect(invoice.past_due?).to be true
      end

      it "returns false when due_date is today or future" do
        expect(build(:invoice, due_date: Date.current).past_due?).to be false
        expect(build(:invoice, due_date: 1.day.from_now).past_due?).to be false
      end
    end

    describe "#days_overdue" do
      it "returns number of days past due" do
        invoice = build(:invoice, due_date: 5.days.ago)
        expect(invoice.days_overdue).to eq(5)
      end

      it "returns 0 when not past due" do
        invoice = build(:invoice, due_date: 5.days.from_now)
        expect(invoice.days_overdue).to eq(0)
      end
    end

    describe "#days_until_due" do
      it "returns number of days until due" do
        invoice = build(:invoice, due_date: 10.days.from_now)
        expect(invoice.days_until_due).to eq(10)
      end

      it "returns 0 when past due" do
        invoice = build(:invoice, due_date: 5.days.ago)
        expect(invoice.days_until_due).to eq(0)
      end
    end

    describe "#payment_status_color" do
      it "returns correct colors for each status" do
        expect(build(:invoice, :draft).payment_status_color).to eq("gray")
        expect(build(:invoice, :sent).payment_status_color).to eq("blue")
        expect(build(:invoice, :viewed).payment_status_color).to eq("indigo")
        expect(build(:invoice, :paid).payment_status_color).to eq("green")
        expect(build(:invoice, :overdue).payment_status_color).to eq("red")
        expect(build(:invoice, :cancelled).payment_status_color).to eq("gray")
      end
    end
  end
end
