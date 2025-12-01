# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicePdfGenerator, type: :service do
  let(:account) { create(:account, name: "Test Business LLC") }
  let(:client) { create(:client, :with_address, account: account, name: "John Smith", company: "Smith Construction") }
  let(:invoice) { create(:invoice, :with_line_items, account: account, client: client) }

  describe ".call" do
    it "returns a successful result" do
      result = described_class.call(invoice)
      expect(result).to be_success
    end

    it "returns PDF data" do
      result = described_class.call(invoice)
      expect(result.pdf).to be_present
      expect(result.pdf).to start_with("%PDF")
    end

    it "includes invoice number in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(invoice.invoice_number)
    end

    it "includes client name in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(client.name)
    end

    it "includes client company in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(client.company)
    end

    it "includes business name in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(account.name)
    end

    it "includes line items in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      invoice.line_items.each do |item|
        expect(text).to include(item.description)
      end
    end

    it "includes total amount in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      # Format will be like "1,000.00" or "1000.00"
      formatted_total = invoice.total_amount.to_s
      expect(text).to include(formatted_total).or include(number_with_precision(invoice.total_amount, precision: 2))
    end

    it "includes issue date in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(invoice.issue_date.strftime("%B %d, %Y")).or include(invoice.issue_date.strftime("%m/%d/%Y"))
    end

    it "includes due date in the PDF" do
      result = described_class.call(invoice)
      text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
      expect(text).to include(invoice.due_date.strftime("%B %d, %Y")).or include(invoice.due_date.strftime("%m/%d/%Y"))
    end

    context "when invoice has notes" do
      let(:invoice) { create(:invoice, account: account, client: client, notes: "Please pay within 30 days") }

      it "includes notes in the PDF" do
        result = described_class.call(invoice)
        text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
        expect(text).to include("Please pay within 30 days")
      end
    end

    context "when invoice has tax" do
      let(:invoice) { create(:invoice, :with_tax, account: account, client: client) }

      it "includes tax amount in the PDF" do
        result = described_class.call(invoice)
        text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
        expect(text).to include("Tax").or include("tax")
      end
    end

    context "when invoice has discount" do
      let(:invoice) { create(:invoice, :with_discount, account: account, client: client) }

      it "includes discount in the PDF" do
        result = described_class.call(invoice)
        text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
        expect(text).to include("Discount").or include("discount")
      end
    end

    context "when invoice is paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      it "shows paid status in the PDF" do
        result = described_class.call(invoice)
        text = PDF::Inspector::Text.analyze(result.pdf).strings.join(" ")
        expect(text).to match(/paid/i)
      end
    end
  end

  describe "#filename" do
    it "generates a filename based on invoice number" do
      generator = described_class.new(invoice)
      expect(generator.filename).to eq("invoice_#{invoice.invoice_number.downcase.gsub(/[^a-z0-9]/, '_')}.pdf")
    end
  end

  private

  def number_with_precision(number, precision:)
    format("%.#{precision}f", number)
  end
end
