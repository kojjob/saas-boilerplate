# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceMailer, type: :mailer do
  let(:account) { create(:account, name: "Test Business LLC") }
  let(:client) { create(:client, :with_address, account: account, email: "client@example.com", name: "John Smith") }
  let(:invoice) { create(:invoice, :with_line_items, account: account, client: client) }

  describe "#send_invoice" do
    let(:mail) { described_class.send_invoice(invoice) }

    it "renders the headers" do
      expect(mail.subject).to include(invoice.invoice_number)
      expect(mail.to).to eq([client.email])
    end

    it "sets the from address correctly" do
      expect(mail.from).to eq(["noreply@example.com"])
    end

    it "includes the invoice number in the body" do
      expect(mail.body.encoded).to include(invoice.invoice_number)
    end

    it "includes the total amount in the body" do
      expect(mail.body.encoded).to include(invoice.total_amount.to_s).or include(ActionController::Base.helpers.number_to_currency(invoice.total_amount))
    end

    it "includes the due date in the body" do
      expect(mail.body.encoded).to include(invoice.due_date.strftime("%B %d, %Y")).or include(invoice.due_date.strftime("%m/%d/%Y"))
    end

    it "includes the client name in the body" do
      expect(mail.body.encoded).to include(client.name)
    end

    it "attaches the PDF invoice" do
      expect(mail.attachments.count).to eq(1)
      attachment = mail.attachments.first
      expect(attachment.filename).to match(/invoice.*\.pdf/i)
      expect(attachment.content_type).to start_with("application/pdf")
    end

    it "generates a PDF attachment that starts with PDF header" do
      attachment = mail.attachments.first
      expect(attachment.body.raw_source).to start_with("%PDF")
    end

    context "with custom recipient" do
      let(:mail) { described_class.send_invoice(invoice, recipient: "alternate@example.com") }

      it "sends to the custom recipient" do
        expect(mail.to).to eq(["alternate@example.com"])
      end
    end

    context "with custom message" do
      let(:custom_message) { "Thank you for your business. Here is your invoice." }
      let(:mail) { described_class.send_invoice(invoice, message: custom_message) }

      it "includes the custom message in the body" do
        expect(mail.body.encoded).to include(custom_message)
      end
    end
  end

  describe "#payment_received" do
    let(:invoice) { create(:invoice, :paid, account: account, client: client) }
    let(:mail) { described_class.payment_received(invoice) }

    it "renders the headers" do
      expect(mail.subject).to include("Payment Received")
      expect(mail.to).to eq([client.email])
    end

    it "includes thank you message" do
      expect(mail.body.encoded).to match(/thank you/i)
    end

    it "includes the invoice number" do
      expect(mail.body.encoded).to include(invoice.invoice_number)
    end

    it "includes the payment amount" do
      expect(mail.body.encoded).to include(invoice.total_amount.to_s).or include(ActionController::Base.helpers.number_to_currency(invoice.total_amount))
    end

    it "does not attach a PDF" do
      expect(mail.attachments.count).to eq(0)
    end
  end

  describe "#payment_reminder" do
    let(:invoice) { create(:invoice, :sent, account: account, client: client) }
    let(:mail) { described_class.payment_reminder(invoice) }

    it "renders the headers" do
      expect(mail.subject).to include("Reminder")
      expect(mail.to).to eq([client.email])
    end

    it "includes the invoice number" do
      expect(mail.body.encoded).to include(invoice.invoice_number)
    end

    it "includes the due date" do
      expect(mail.body.encoded).to include(invoice.due_date.strftime("%B %d, %Y")).or include(invoice.due_date.strftime("%m/%d/%Y"))
    end

    it "includes the total amount" do
      expect(mail.body.encoded).to include(invoice.total_amount.to_s).or include(ActionController::Base.helpers.number_to_currency(invoice.total_amount))
    end

    it "includes client name" do
      expect(mail.body.encoded).to include(client.name)
    end

    it "includes account name" do
      expect(mail.body.encoded).to include(account.name)
    end

    context "when invoice is overdue" do
      let(:invoice) { create(:invoice, :overdue, account: account, client: client) }

      it "mentions overdue in subject" do
        expect(mail.subject).to match(/overdue/i)
      end

      it "includes days overdue in the body" do
        expect(mail.body.encoded).to include(invoice.days_overdue.to_s)
      end

      it "includes overdue messaging" do
        expect(mail.body.encoded).to match(/overdue|past due/i)
      end
    end

    context "when invoice is due soon" do
      let(:invoice) do
        create(:invoice, :sent,
          account: account,
          client: client,
          due_date: 2.days.from_now,
          issue_date: Date.current
        )
      end

      it "includes upcoming due date messaging" do
        expect(mail.body.encoded).to match(/due soon|due in/i)
      end

      it "mentions due soon in subject" do
        expect(mail.subject).to match(/due soon/i)
      end
    end
  end
end
