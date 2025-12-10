# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentReminderJob, type: :job do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account, email: "client@example.com") }

  describe "#perform" do
    context "with reminder_type: :due_soon" do
      let!(:due_soon_invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :sent,
          due_date: 3.days.from_now,
          sent_at: 10.days.ago
        )
      end

      it "sends reminders for invoices due soon" do
        expect {
          described_class.new.perform(:due_soon)
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "logs the number of reminders sent" do
        allow(Rails.logger).to receive(:info)
        described_class.new.perform(:due_soon)
        expect(Rails.logger).to have_received(:info).with(/Payment reminder job completed.*sent_count: 1/i)
      end
    end

    context "with reminder_type: :overdue" do
      let!(:overdue_invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :overdue,
          issue_date: 20.days.ago,
          due_date: 5.days.ago,
          sent_at: 15.days.ago
        )
      end

      it "sends reminders for overdue invoices" do
        expect {
          described_class.new.perform(:overdue)
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "marks sent invoices as overdue" do
        sent_invoice = create(:invoice,
          account: account,
          client: client,
          status: :sent,
          issue_date: 20.days.ago,
          due_date: 3.days.ago,
          sent_at: 15.days.ago
        )

        described_class.new.perform(:overdue)
        expect(sent_invoice.reload.status).to eq("overdue")
      end
    end

    context "with reminder_type: :single and invoice_id" do
      let(:invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :sent,
          due_date: 3.days.from_now,
          sent_at: 5.days.ago
        )
      end

      it "sends a reminder for a specific invoice" do
        expect {
          described_class.new.perform(:single, invoice.id)
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "updates reminder tracking on the invoice" do
        freeze_time do
          described_class.new.perform(:single, invoice.id)
          expect(invoice.reload.reminder_sent_at).to eq(Time.current)
          expect(invoice.reload.reminder_count).to eq(1)
        end
      end

      it "does not send reminder if invoice not found" do
        expect {
          described_class.new.perform(:single, "non-existent-id")
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end
    end

    context "with force option" do
      let(:invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :sent,
          due_date: 3.days.from_now,
          reminder_sent_at: 1.day.ago,
          reminder_count: 1
        )
      end

      it "sends reminder even within cooldown period" do
        expect {
          described_class.new.perform(:single, invoice.id, force: true)
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end
    end
  end

  describe "job configuration" do
    it "is enqueued in the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  describe "scheduling" do
    it "can be scheduled for later execution" do
      expect {
        described_class.set(wait: 1.hour).perform_later(:due_soon)
      }.to have_enqueued_job(described_class).with(:due_soon)
    end
  end
end
