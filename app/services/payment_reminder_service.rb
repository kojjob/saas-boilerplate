# frozen_string_literal: true

# Service to send payment reminders for invoices
#
# Usage:
#   result = PaymentReminderService.new(invoice).call
#   result = PaymentReminderService.new(invoice, force: true).call
#
#   # Batch operations
#   PaymentReminderService.send_due_soon_reminders
#   PaymentReminderService.send_overdue_reminders
#
class PaymentReminderService
  # Default cooldown period between reminders (in days)
  REMINDER_COOLDOWN_DAYS = 3

  # Maximum number of reminders to send per invoice
  MAX_REMINDERS = 5

  # Days before due date to start sending "due soon" reminders
  DUE_SOON_DAYS = 7

  attr_reader :invoice, :force

  def initialize(invoice, force: false)
    @invoice = invoice
    @force = force
  end

  # Send a payment reminder for the invoice
  # @return [Hash] result with :success and :message keys
  def call
    return failure_result("Invoice has already been paid") if invoice.paid?
    return failure_result("Invoice has not been sent yet") if invoice.draft?
    return failure_result("Invoice has been cancelled") if invoice.cancelled?
    return failure_result("Reminder was sent recently") if !force && sent_recently?
    return failure_result("Maximum number of reminders reached") if !force && max_reminders_reached?

    send_reminder
    update_reminder_tracking
    success_result("Payment reminder sent successfully")
  rescue StandardError => e
    Rails.logger.error("[PaymentReminderService] Error: #{e.message}")
    failure_result("Failed to send reminder: #{e.message}")
  end

  # Send reminders for all invoices due within DUE_SOON_DAYS
  # @return [Hash] result with :sent_count
  def self.send_due_soon_reminders
    sent_count = 0

    Invoice.unpaid
           .where("due_date <= ?", DUE_SOON_DAYS.days.from_now)
           .where("due_date >= ?", Date.current)
           .find_each do |invoice|
      result = new(invoice).call
      sent_count += 1 if result[:success]
    end

    { sent_count: sent_count }
  end

  # Send reminders for all overdue invoices
  # Marks "sent" invoices as "overdue" if past due
  # @return [Hash] result with :sent_count
  def self.send_overdue_reminders
    sent_count = 0

    # First mark sent invoices as overdue if past due
    Invoice.where(status: :sent)
           .where("due_date < ?", Date.current)
           .find_each do |invoice|
      invoice.update!(status: :overdue)
    end

    # Now send reminders to all unpaid overdue invoices
    Invoice.unpaid
           .where("due_date < ?", Date.current)
           .find_each do |invoice|
      result = new(invoice).call
      sent_count += 1 if result[:success]
    end

    { sent_count: sent_count }
  end

  private

  def send_reminder
    InvoiceMailer.payment_reminder(invoice).deliver_later
  end

  def update_reminder_tracking
    invoice.update!(
      reminder_sent_at: Time.current,
      reminder_count: invoice.reminder_count + 1
    )
  end

  def sent_recently?
    return false if invoice.reminder_sent_at.nil?

    invoice.reminder_sent_at > REMINDER_COOLDOWN_DAYS.days.ago
  end

  def max_reminders_reached?
    invoice.reminder_count >= MAX_REMINDERS
  end

  def success_result(message)
    { success: true, message: message }
  end

  def failure_result(message)
    { success: false, message: message }
  end
end
