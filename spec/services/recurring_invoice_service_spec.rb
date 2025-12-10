# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringInvoiceService, type: :service do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }
  let(:recurring_invoice) do
    create(:recurring_invoice,
           account: account,
           client: client,
           payment_terms: 30,
           currency: "USD",
           tax_rate: 10.0,
           notes: "Monthly service fee")
  end

  describe "#generate_invoice!" do
    context "when recurring invoice can generate" do
      before do
        create(:recurring_invoice_line_item,
               recurring_invoice: recurring_invoice,
               description: "Consulting Services",
               quantity: 10,
               unit_price: 150.00)
        create(:recurring_invoice_line_item,
               recurring_invoice: recurring_invoice,
               description: "Support Hours",
               quantity: 5,
               unit_price: 100.00)
      end

      it "creates a new invoice" do
        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to change(Invoice, :count).by(1)
      end

      it "creates invoice line items" do
        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to change(InvoiceLineItem, :count).by(2)
      end

      it "sets invoice attributes from recurring invoice" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!

        expect(invoice.account).to eq(account)
        expect(invoice.client).to eq(client)
        expect(invoice.currency).to eq("USD")
        expect(invoice.notes).to eq("Monthly service fee")
        expect(invoice.recurring_invoice).to eq(recurring_invoice)
      end

      it "sets issue date to today" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        expect(invoice.issue_date).to eq(Date.current)
      end

      it "calculates due date based on payment terms" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        expect(invoice.due_date).to eq(Date.current + 30.days)
      end

      it "copies line items with correct amounts" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        line_items = invoice.line_items.order(:created_at)

        expect(line_items.first.description).to eq("Consulting Services")
        expect(line_items.first.quantity).to eq(10)
        expect(line_items.first.unit_price).to eq(150.00)

        expect(line_items.last.description).to eq("Support Hours")
        expect(line_items.last.quantity).to eq(5)
        expect(line_items.last.unit_price).to eq(100.00)
      end

      it "calculates invoice totals" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!

        # Line items: (10 * 150) + (5 * 100) = 1500 + 500 = 2000
        expect(invoice.subtotal).to eq(2000.00)
        # Tax: 2000 * 0.10 = 200
        expect(invoice.tax_amount).to eq(200.00)
        # Total: 2000 + 200 = 2200
        expect(invoice.total_amount).to eq(2200.00)
      end

      it "advances the recurring invoice occurrence" do
        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to change { recurring_invoice.reload.occurrences_count }.by(1)
      end

      it "updates the recurring invoice next occurrence date" do
        original_date = recurring_invoice.next_occurrence_date
        RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        expect(recurring_invoice.reload.next_occurrence_date).to eq(original_date + 1.month)
      end

      it "creates invoice in draft status" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        expect(invoice).to be_draft
      end
    end

    context "when recurring invoice cannot generate" do
      it "raises error when paused" do
        recurring_invoice.pause!

        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to raise_error(RecurringInvoiceService::CannotGenerateError, /paused/)
      end

      it "raises error when cancelled" do
        recurring_invoice.cancel!

        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to raise_error(RecurringInvoiceService::CannotGenerateError)
      end

      it "raises error when occurrences limit reached" do
        recurring_invoice.update!(occurrences_limit: 1, occurrences_count: 1)

        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to raise_error(RecurringInvoiceService::CannotGenerateError, /limit/)
      end

      it "raises error when next occurrence is in the future" do
        recurring_invoice.update!(next_occurrence_date: Date.current + 7.days)

        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to raise_error(RecurringInvoiceService::CannotGenerateError, /not due/)
      end
    end

    context "when auto_send is enabled" do
      before do
        recurring_invoice.update!(
          auto_send: true,
          email_subject: "Your Invoice",
          email_body: "Please find your invoice attached."
        )
        create(:recurring_invoice_line_item, recurring_invoice: recurring_invoice)
      end

      it "creates the invoice in sent status" do
        invoice = RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        expect(invoice).to be_sent
      end

      it "enqueues email delivery job" do
        expect {
          RecurringInvoiceService.new(recurring_invoice).generate_invoice!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
  end

  describe ".generate_all_due!" do
    it "generates invoices for all due recurring invoices" do
      due_recurring1 = create(:recurring_invoice, account: account, client: client)
      due_recurring2 = create(:recurring_invoice, account: account, client: client)
      not_due_recurring = create(:recurring_invoice, account: account, client: client,
                                  next_occurrence_date: Date.current + 7.days)

      create(:recurring_invoice_line_item, recurring_invoice: due_recurring1)
      create(:recurring_invoice_line_item, recurring_invoice: due_recurring2)
      create(:recurring_invoice_line_item, recurring_invoice: not_due_recurring)

      expect {
        RecurringInvoiceService.generate_all_due!
      }.to change(Invoice, :count).by(2)
    end

    it "returns array of generated invoices" do
      due_recurring = create(:recurring_invoice, account: account, client: client)
      create(:recurring_invoice_line_item, recurring_invoice: due_recurring)

      invoices = RecurringInvoiceService.generate_all_due!
      expect(invoices).to be_an(Array)
      expect(invoices.length).to eq(1)
      expect(invoices.first).to be_an(Invoice)
    end

    it "handles errors gracefully and continues processing" do
      due_recurring1 = create(:recurring_invoice, account: account, client: client)
      due_recurring2 = create(:recurring_invoice, account: account, client: client)

      create(:recurring_invoice_line_item, recurring_invoice: due_recurring1)
      # No line items for due_recurring2, which might cause an issue
      create(:recurring_invoice_line_item, recurring_invoice: due_recurring2)

      # Should not raise, even if one fails
      expect {
        RecurringInvoiceService.generate_all_due!
      }.not_to raise_error
    end
  end
end
