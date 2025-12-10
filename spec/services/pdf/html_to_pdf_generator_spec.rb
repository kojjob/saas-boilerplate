# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pdf::HtmlToPdfGenerator, type: :service do
  describe ".call" do
    # Mock Grover since Puppeteer may not be available in test environment
    let(:mock_grover) { instance_double(Grover) }
    let(:mock_pdf_content) { "%PDF-1.4 mock pdf content" }

    before do
      allow(Grover).to receive(:new).and_return(mock_grover)
      allow(mock_grover).to receive(:to_pdf).and_return(mock_pdf_content)
    end

    context "with valid HTML content" do
      let(:html) { "<html><body><h1>Test PDF</h1><p>Sample content</p></body></html>" }

      subject(:result) { described_class.call(html: html) }

      it "returns a successful result" do
        expect(result.success?).to be true
      end

      it "returns PDF binary data" do
        expect(result.data[:pdf]).to be_present
        expect(result.data[:pdf]).to be_a(String)
      end

      it "returns valid PDF content starting with PDF header" do
        expect(result.data[:pdf]).to start_with("%PDF")
      end

      it "has no error" do
        expect(result.error).to be_nil
      end

      it "calls Grover with the HTML content" do
        result
        expect(Grover).to have_received(:new).with(html, hash_including(:format, :print_background))
      end
    end

    context "with complex HTML content" do
      let(:html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; }
              .header { color: #333; font-size: 24px; }
              .content { margin: 20px; padding: 10px; }
              table { border-collapse: collapse; width: 100%; }
              td, th { border: 1px solid #ddd; padding: 8px; }
            </style>
          </head>
          <body>
            <div class="header">Invoice #12345</div>
            <div class="content">
              <table>
                <tr><th>Description</th><th>Amount</th></tr>
                <tr><td>Service 1</td><td>$100.00</td></tr>
                <tr><td>Service 2</td><td>$200.00</td></tr>
              </table>
            </div>
          </body>
          </html>
        HTML
      end

      subject(:result) { described_class.call(html: html) }

      it "generates PDF successfully" do
        expect(result.success?).to be true
        expect(result.data[:pdf]).to start_with("%PDF")
      end
    end

    context "with custom options" do
      let(:html) { "<html><body><h1>Custom Options Test</h1></body></html>" }
      let(:options) do
        {
          format: "A4",
          print_background: false,
          margin: {
            top: "1in",
            bottom: "1in",
            left: "1in",
            right: "1in"
          }
        }
      end

      subject(:result) { described_class.call(html: html, options: options) }

      it "generates PDF with custom options" do
        expect(result.success?).to be true
        expect(result.data[:pdf]).to be_present
      end

      it "passes custom options to Grover" do
        result
        expect(Grover).to have_received(:new).with(
          html,
          hash_including(format: "A4", print_background: false)
        )
      end
    end

    context "when Grover raises an error" do
      let(:html) { "<html><body>Test</body></html>" }

      before do
        allow(mock_grover).to receive(:to_pdf).and_raise(StandardError, "Puppeteer error")
      end

      subject(:result) { described_class.call(html: html) }

      it "returns a failure result" do
        expect(result.success?).to be false
      end

      it "includes the error message" do
        expect(result.error).to include("Puppeteer error")
      end
    end

    context "with blank HTML content" do
      let(:html) { "" }

      subject(:result) { described_class.call(html: html) }

      it "returns a failure result" do
        expect(result.success?).to be false
      end

      it "has an error message" do
        expect(result.error).to be_present
        expect(result.error).to include("HTML content is required")
      end

      it "has no PDF data" do
        expect(result.data[:pdf]).to be_nil
      end
    end

    context "with nil HTML content" do
      let(:html) { nil }

      subject(:result) { described_class.call(html: html) }

      it "returns a failure result" do
        expect(result.success?).to be false
      end

      it "has an error message" do
        expect(result.error).to include("HTML content is required")
      end
    end

    context "with whitespace-only HTML content" do
      let(:html) { "   \n\t  " }

      subject(:result) { described_class.call(html: html) }

      it "returns a failure result" do
        expect(result.success?).to be false
      end

      it "has an error message about HTML content" do
        expect(result.error).to include("HTML content is required")
      end
    end
  end

  describe "default options" do
    it "uses Letter format by default" do
      generator = described_class.new(html: "<h1>Test</h1>")
      expect(generator.send(:options)[:format]).to eq("Letter")
    end

    it "prints background by default" do
      generator = described_class.new(html: "<h1>Test</h1>")
      expect(generator.send(:options)[:print_background]).to be true
    end

    it "prefers CSS page size by default" do
      generator = described_class.new(html: "<h1>Test</h1>")
      expect(generator.send(:options)[:prefer_css_page_size]).to be true
    end

    it "sets default margins" do
      generator = described_class.new(html: "<h1>Test</h1>")
      margin = generator.send(:options)[:margin]
      expect(margin[:top]).to eq("0.5in")
      expect(margin[:bottom]).to eq("0.5in")
      expect(margin[:left]).to eq("0.5in")
      expect(margin[:right]).to eq("0.5in")
    end
  end

  describe "option merging" do
    it "overrides default options with custom options" do
      custom_options = { format: "A4", margin: { top: "1in" } }
      generator = described_class.new(html: "<h1>Test</h1>", options: custom_options)

      merged_options = generator.send(:options)
      expect(merged_options[:format]).to eq("A4")
      expect(merged_options[:margin][:top]).to eq("1in")
    end

    it "preserves default options not overridden" do
      custom_options = { format: "A4" }
      generator = described_class.new(html: "<h1>Test</h1>", options: custom_options)

      merged_options = generator.send(:options)
      expect(merged_options[:print_background]).to be true
    end
  end
end
