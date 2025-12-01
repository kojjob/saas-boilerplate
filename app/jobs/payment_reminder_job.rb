# frozen_string_literal: true

# Background job for sending payment reminders
#
# Usage:
#   # Send reminders for invoices due soon (within 7 days)
#   PaymentReminderJob.perform_later(:due_soon)
#
#   # Send reminders for overdue invoices
#   PaymentReminderJob.perform_later(:overdue)
#
#   # Send reminder for a specific invoice
#   PaymentReminderJob.perform_later(:single, invoice_id)
#
#   # Force send (ignore cooldown)
#   PaymentReminderJob.perform_later(:single, invoice_id, force: true)
#
class PaymentReminderJob < ApplicationJob
  queue_as :default

  # @param reminder_type [Symbol] :due_soon, :overdue, or :single
  # @param invoice_id [String, nil] Required when reminder_type is :single
  # @param force [Boolean] Skip cooldown check when true
  def perform(reminder_type, invoice_id = nil, force: false)
    result = case reminder_type.to_sym
             when :due_soon
               send_due_soon_reminders
             when :overdue
               send_overdue_reminders
             when :single
               send_single_reminder(invoice_id, force: force)
             else
               { success: false, message: "Unknown reminder type: #{reminder_type}" }
             end

    log_result(reminder_type, result)
    result
  end

  private

  def send_due_soon_reminders
    PaymentReminderService.send_due_soon_reminders
  end

  def send_overdue_reminders
    PaymentReminderService.send_overdue_reminders
  end

  def send_single_reminder(invoice_id, force: false)
    invoice = Invoice.find_by(id: invoice_id)

    if invoice.nil?
      Rails.logger.warn "[PaymentReminderJob] Invoice not found: #{invoice_id}"
      return { success: false, message: "Invoice not found" }
    end

    PaymentReminderService.new(invoice, force: force).call
  end

  def log_result(reminder_type, result)
    message = if result[:sent_count]
                "Payment reminder job completed (#{reminder_type}): sent_count: #{result[:sent_count]}"
              elsif result[:success]
                "Payment reminder job completed (#{reminder_type}): #{result[:message]}"
              else
                "Payment reminder job completed (#{reminder_type}): Failed - #{result[:message]}"
              end

    Rails.logger.info message
  end
end
