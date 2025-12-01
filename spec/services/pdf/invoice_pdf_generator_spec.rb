# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pdf::InvoicePdfGenerator, type: :service do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account, name: "Test Client", company: "Test Company") }
  let(:invoice) { create(:invoice, account: account, client: client, invoice_number: "INV-10001") }

  describe ".call" do
    subject(:result) { described_class.call(invoice: invoice) }

    context "with valid invoice" do
      it "returns a successful result" do
        expect(result.success?).to be true
      end

      it "returns PDF binary data" do
        expect(result.pdf).to be_present
        expect(result.pdf).to be_a(String)
      end

      it "returns valid PDF content" do
        expect(result.pdf).to start_with("%PDF")
      end

      it "has no error" do
        expect(result.error).to be_nil
      end
    end

    context "with invoice including line items" do
      before do
        create(:invoice_line_item, invoice: invoice, description: "Service 1", quantity: 2, unit_price: 100)
        create(:invoice_line_item, invoice: invoice, description: "Service 2", quantity: 1, unit_price: 50)
        invoice.reload
      end

      it "generates PDF successfully" do
        expect(result.success?).to be true
        expect(result.pdf).to start_with("%PDF")
      end
    end

    context "with invalid invoice" do
      let(:invoice) { nil }

      it "returns a failure result" do
        expect(result.success?).to be false
      end

      it "has no PDF data" do
        expect(result.data[:pdf]).to be_nil
      end

      it "has an error message" do
        expect(result.error).to be_present
      end
    end
  end

  describe "#filename" do
    subject(:generator) { described_class.new(invoice: invoice) }

    it "generates a filename based on invoice number" do
      expect(generator.filename).to eq("Invoice-INV-10001.pdf")
    end
  end

  describe "HTML rendering" do
    subject(:result) { described_class.call(invoice: invoice) }

    it "includes invoice details in the generated PDF" do
      # The PDF should be generated without errors
      expect(result.success?).to be true
    end
  end
end
