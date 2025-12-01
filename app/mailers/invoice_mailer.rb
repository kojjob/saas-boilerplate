# frozen_string_literal: true

class InvoiceMailer < ApplicationMailer
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

    subject = if @is_overdue
      "OVERDUE: Payment Reminder for Invoice #{@invoice.invoice_number}"
    else
      "Reminder: Invoice #{@invoice.invoice_number} is Due Soon"
    end

    mail(
      to: @client.email,
      subject: subject
    )
  end
end
