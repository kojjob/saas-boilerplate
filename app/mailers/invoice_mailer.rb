# frozen_string_literal: true

class InvoiceMailer < ApplicationMailer
  helper :invoices

  def send_invoice(invoice, recipient: nil, message: nil)
    @invoice = invoice
    @client = invoice.client
    @account = invoice.account
    @custom_message = message

    # Generate PDF attachment
    pdf_result = InvoicePdfGenerator.call(invoice)
    if pdf_result.success?
      attachments[pdf_result.filename] = {
        mime_type: "application/pdf",
        content: pdf_result.pdf
      }
    end

    mail(
      to: recipient || @client.email,
      subject: "Invoice #{@invoice.invoice_number} from #{@account.name}"
    )
  end

  def payment_received(invoice)
    @invoice = invoice
    @client = invoice.client
    @account = invoice.account

    mail(
      to: @client.email,
      subject: "Payment Received - Invoice #{@invoice.invoice_number}"
    )
  end

  def payment_reminder(invoice)
    @invoice = invoice
    @client = invoice.client
    @account = invoice.account
    @is_overdue = invoice.past_due?
    @days_overdue = invoice.days_overdue
    @days_until_due = invoice.days_until_due

    mail(
      to: @client.email,
      subject: payment_reminder_subject
    )
  end

  private

  def payment_reminder_subject
    if @is_overdue
      "Payment Reminder: Invoice #{@invoice.invoice_number} is Overdue"
    else
      "Payment Reminder: Invoice #{@invoice.invoice_number} Due Soon"
    end
  end
end
