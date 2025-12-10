# frozen_string_literal: true

class RecurringInvoiceService
  class CannotGenerateError < StandardError; end

  attr_reader :recurring_invoice

  def initialize(recurring_invoice)
    @recurring_invoice = recurring_invoice
  end

  # Generate an invoice from the recurring invoice template
  def generate_invoice!
    validate_can_generate!

    invoice = nil

    ActiveRecord::Base.transaction do
      invoice = create_invoice
      copy_line_items(invoice)
      calculate_totals(invoice)
      invoice.save!

      if recurring_invoice.auto_send?
        send_invoice(invoice)
      end

      recurring_invoice.advance_next_occurrence!
    end

    invoice
  end

  # Class method to generate all due invoices
  def self.generate_all_due!
    generated_invoices = []

    RecurringInvoice.due_for_generation.find_each do |recurring|
      begin
        invoice = new(recurring).generate_invoice!
        generated_invoices << invoice
        Rails.logger.info("Generated invoice #{invoice.invoice_number} from recurring invoice #{recurring.id}")
      rescue => e
        Rails.logger.error("Failed to generate invoice for recurring #{recurring.id}: #{e.message}")
      end
    end

    generated_invoices
  end

  private

  def validate_can_generate!
    unless recurring_invoice.active?
      raise CannotGenerateError, "Cannot generate invoice: recurring invoice is #{recurring_invoice.status}"
    end

    if recurring_invoice.next_occurrence_date.nil? || recurring_invoice.next_occurrence_date > Date.current
      raise CannotGenerateError, "Cannot generate invoice: not due yet"
    end

    if recurring_invoice.occurrences_limit.present? &&
       recurring_invoice.occurrences_count >= recurring_invoice.occurrences_limit
      raise CannotGenerateError, "Cannot generate invoice: occurrences limit reached"
    end

    if recurring_invoice.end_date.present? && recurring_invoice.end_date < Date.current
      raise CannotGenerateError, "Cannot generate invoice: end date has passed"
    end
  end

  def create_invoice
    Invoice.new(
      account: recurring_invoice.account,
      client: recurring_invoice.client,
      project: recurring_invoice.project,
      recurring_invoice: recurring_invoice,
      issue_date: Date.current,
      due_date: Date.current + recurring_invoice.payment_terms.days,
      currency: recurring_invoice.currency,
      tax_rate: recurring_invoice.tax_rate,
      notes: recurring_invoice.notes,
      status: :draft
    )
  end

  def copy_line_items(invoice)
    recurring_invoice.line_items.each do |recurring_line_item|
      invoice.line_items.build(
        description: recurring_line_item.description,
        quantity: recurring_line_item.quantity,
        unit_price: recurring_line_item.unit_price,
        amount: recurring_line_item.amount,
        position: recurring_line_item.position
      )
    end
  end

  def calculate_totals(invoice)
    subtotal = invoice.line_items.sum(&:amount)
    tax_amount = (subtotal * (invoice.tax_rate || 0) / 100).round(2)
    total_amount = subtotal + tax_amount

    invoice.subtotal = subtotal
    invoice.tax_amount = tax_amount
    invoice.total_amount = total_amount
  end

  def send_invoice(invoice)
    invoice.status = :sent
    invoice.sent_at = Time.current

    # Queue email delivery with custom message from recurring invoice settings
    InvoiceMailer.send_invoice(
      invoice,
      message: recurring_invoice.email_body
    ).deliver_later
  end
end
