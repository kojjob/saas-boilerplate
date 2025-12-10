# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentReminderService do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account, email: "client@example.com") }

  describe "#call" do
    context "when invoice is eligible for reminder" do
      let(:invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :sent,
          due_date: 3.days.from_now,
          sent_at: 5.days.ago
        )
      end

      it "sends a payment reminder email" do
        expect {
          described_class.new(invoice).call
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "updates reminder_sent_at timestamp" do
        freeze_time do
          described_class.new(invoice).call
          expect(invoice.reload.reminder_sent_at).to eq(Time.current)
        end
      end

      it "increments reminder_count" do
        expect {
          described_class.new(invoice).call
        }.to change { invoice.reload.reminder_count }.by(1)
      end

      it "returns a success result" do
        result = described_class.new(invoice).call
        expect(result[:success]).to be true
        expect(result[:message]).to include("sent")
      end
    end

    context "when invoice is already paid" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :paid) }

      it "does not send a reminder" do
        expect {
          described_class.new(invoice).call
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "returns a failure result" do
        result = described_class.new(invoice).call
        expect(result[:success]).to be false
        expect(result[:message]).to include("paid")
      end
    end

    context "when invoice is a draft" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :draft) }

      it "does not send a reminder" do
        expect {
          described_class.new(invoice).call
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "returns a failure result" do
        result = described_class.new(invoice).call
        expect(result[:success]).to be false
        expect(result[:message]).to include("not been sent")
      end
    end

    context "when invoice is cancelled" do
      let(:invoice) { create(:invoice, account: account, client: client, status: :cancelled) }

      it "does not send a reminder" do
        expect {
          described_class.new(invoice).call
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end
    end

    context "when reminder was sent recently" do
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

      it "does not send another reminder within cooldown period" do
        expect {
          described_class.new(invoice).call
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "returns a failure result with cooldown message" do
        result = described_class.new(invoice).call
        expect(result[:success]).to be false
        expect(result[:message]).to include("recently")
      end
    end

    context "when max reminders have been sent" do
      let(:invoice) do
        create(:invoice,
          account: account,
          client: client,
          status: :sent,
          due_date: 3.days.from_now,
          reminder_sent_at: 10.days.ago,
          reminder_count: 5
        )
      end

      it "does not send more reminders" do
        expect {
          described_class.new(invoice).call
        }.not_to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end

      it "returns a failure result" do
        result = described_class.new(invoice).call
        expect(result[:success]).to be false
        expect(result[:message].downcase).to include("maximum")
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
          described_class.new(invoice, force: true).call
        }.to have_enqueued_mail(InvoiceMailer, :payment_reminder)
      end
    end
  end

  describe ".send_due_soon_reminders" do
    let!(:due_soon_invoice) do
      create(:invoice,
        account: account,
        client: client,
        status: :sent,
        due_date: 3.days.from_now,
        sent_at: 10.days.ago
      )
    end

    let!(:due_later_invoice) do
      create(:invoice,
        account: account,
        client: client,
        status: :sent,
        due_date: 14.days.from_now,
        sent_at: 10.days.ago
      )
    end

    let!(:paid_invoice) do
      create(:invoice,
        account: account,
        client: client,
        status: :paid,
        due_date: 3.days.from_now
      )
    end

    it "sends reminders for invoices due within 7 days" do
      expect {
        described_class.send_due_soon_reminders
      }.to have_enqueued_mail(InvoiceMailer, :payment_reminder).once
    end

    it "returns count of reminders sent" do
      result = described_class.send_due_soon_reminders
      expect(result[:sent_count]).to eq(1)
    end
  end

  describe ".send_overdue_reminders" do
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

    let!(:sent_overdue_invoice) do
      create(:invoice,
        account: account,
        client: client,
        status: :sent,
        issue_date: 20.days.ago,
        due_date: 3.days.ago,
        sent_at: 15.days.ago
      )
    end

    let!(:paid_invoice) do
      create(:invoice,
        account: account,
        client: client,
        status: :paid,
        issue_date: 20.days.ago,
        due_date: 5.days.ago
      )
    end

    it "sends reminders for overdue invoices" do
      expect {
        described_class.send_overdue_reminders
      }.to have_enqueued_mail(InvoiceMailer, :payment_reminder).twice
    end

    it "marks sent invoices as overdue" do
      described_class.send_overdue_reminders
      expect(sent_overdue_invoice.reload.status).to eq("overdue")
    end
  end
end
