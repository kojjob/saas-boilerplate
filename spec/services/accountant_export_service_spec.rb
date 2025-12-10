# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountantExportService do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }
  let(:project) { create(:project, account: account, client: client) }
  let(:user) { create(:user, :confirmed) }

  before do
    create(:membership, user: user, account: account, role: "owner")
  end

  describe "#initialize" do
    it "accepts an account and year" do
      service = described_class.new(account, year: 2024)
      expect(service).to be_a(AccountantExportService)
    end

    it "defaults to current year if not provided" do
      service = described_class.new(account)
      expect(service.year).to eq(Date.current.year)
    end
  end

  describe "#generate_bundle" do
    let(:service) { described_class.new(account, year: 2024) }

    context "with invoices" do
      let!(:invoice_2024) do
        create(:invoice,
          account: account,
          client: client,
          issue_date: Date.new(2024, 3, 15),
          due_date: Date.new(2024, 4, 15),
          status: :paid,
          paid_at: Time.new(2024, 3, 20),
          subtotal: 1000.00,
          tax_amount: 100.00,
          total_amount: 1100.00
        )
      end

      let!(:invoice_2023) do
        create(:invoice,
          account: account,
          client: client,
          issue_date: Date.new(2023, 12, 1),
          due_date: Date.new(2024, 1, 1),
          status: :paid
        )
      end

      it "returns a result object" do
        result = service.generate_bundle
        expect(result).to respond_to(:success?)
        expect(result).to respond_to(:data)
      end

      it "generates a ZIP file" do
        result = service.generate_bundle
        expect(result.success?).to be true
        expect(result.data[:zip_path]).to be_present
        expect(File.exist?(result.data[:zip_path])).to be true
      end

      it "includes invoices.csv in the bundle" do
        result = service.generate_bundle
        zip_contents = extract_zip_filenames(result.data[:zip_path])
        expect(zip_contents).to include("invoices.csv")
      end

      it "only includes invoices from the specified year" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "invoices.csv")
        expect(csv_content).to include(invoice_2024.invoice_number)
        expect(csv_content).not_to include(invoice_2023.invoice_number)
      end

      it "includes proper CSV headers for invoices" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "invoices.csv")
        headers = csv_content.split("\n").first
        expect(headers).to include("Invoice Number")
        expect(headers).to include("Client")
        expect(headers).to include("Issue Date")
        expect(headers).to include("Due Date")
        expect(headers).to include("Status")
        expect(headers).to include("Total")
      end
    end

    context "with time entries" do
      let!(:time_entry_2024) do
        create(:time_entry,
          account: account,
          project: project,
          user: user,
          date: Date.new(2024, 6, 15),
          hours: 8.0,
          hourly_rate: 100.00,
          total_amount: 800.00,
          description: "Development work"
        )
      end

      it "includes time_entries.csv in the bundle" do
        result = service.generate_bundle
        zip_contents = extract_zip_filenames(result.data[:zip_path])
        expect(zip_contents).to include("time_entries.csv")
      end

      it "includes proper CSV headers for time entries" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "time_entries.csv")
        headers = csv_content.split("\n").first
        expect(headers).to include("Date")
        expect(headers).to include("Project")
        expect(headers).to include("Hours")
        expect(headers).to include("Hourly Rate")
        expect(headers).to include("Total")
      end
    end

    context "with material entries" do
      let!(:material_entry_2024) do
        create(:material_entry,
          account: account,
          project: project,
          user: user,
          date: Date.new(2024, 7, 10),
          name: "Copper Pipe",
          quantity: 10,
          unit_cost: 25.00,
          total_amount: 250.00
        )
      end

      it "includes materials.csv in the bundle" do
        result = service.generate_bundle
        zip_contents = extract_zip_filenames(result.data[:zip_path])
        expect(zip_contents).to include("materials.csv")
      end

      it "includes proper CSV headers for materials" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "materials.csv")
        headers = csv_content.split("\n").first
        expect(headers).to include("Date")
        expect(headers).to include("Material")
        expect(headers).to include("Quantity")
        expect(headers).to include("Unit Cost")
        expect(headers).to include("Total")
      end
    end

    context "with profit/loss summary" do
      let!(:paid_invoice) do
        create(:invoice,
          account: account,
          client: client,
          issue_date: Date.new(2024, 3, 1),
          due_date: Date.new(2024, 4, 1),
          status: :paid,
          total_amount: 5000.00
        )
      end

      let!(:material_entry) do
        create(:material_entry,
          account: account,
          project: project,
          user: user,
          date: Date.new(2024, 3, 15),
          name: "Materials",
          quantity: 1,
          unit_cost: 1000.00,
          markup_percentage: 0
        )
      end

      it "includes profit_loss_summary.csv in the bundle" do
        result = service.generate_bundle
        zip_contents = extract_zip_filenames(result.data[:zip_path])
        expect(zip_contents).to include("profit_loss_summary.csv")
      end

      it "calculates total revenue from paid invoices" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "profit_loss_summary.csv")
        expect(csv_content).to include("Total Revenue")
        expect(csv_content).to include("5000")
      end

      it "calculates total costs from materials" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "profit_loss_summary.csv")
        expect(csv_content).to include("Total Costs")
        expect(csv_content).to include("1000")
      end

      it "calculates net profit" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "profit_loss_summary.csv")
        expect(csv_content).to include("Net Profit")
        expect(csv_content).to include("4000")
      end
    end

    context "with no data" do
      it "still generates a valid bundle with empty CSVs" do
        result = service.generate_bundle
        expect(result.success?).to be true
        expect(File.exist?(result.data[:zip_path])).to be true
      end
    end

    context "multi-tenant isolation" do
      let(:other_account) { create(:account) }
      let(:other_client) { create(:client, account: other_account) }

      let!(:other_invoice) do
        create(:invoice,
          account: other_account,
          client: other_client,
          issue_date: Date.new(2024, 5, 1),
          due_date: Date.new(2024, 6, 1)
        )
      end

      it "only includes data from the specified account" do
        result = service.generate_bundle
        csv_content = extract_csv_from_zip(result.data[:zip_path], "invoices.csv")
        expect(csv_content).not_to include(other_invoice.invoice_number)
      end
    end
  end

  describe "#cleanup" do
    let(:service) { described_class.new(account, year: 2024) }

    it "removes the generated ZIP file" do
      result = service.generate_bundle
      zip_path = result.data[:zip_path]
      expect(File.exist?(zip_path)).to be true

      service.cleanup
      expect(File.exist?(zip_path)).to be false
    end
  end

  # Helper methods for extracting ZIP contents
  def extract_zip_filenames(zip_path)
    filenames = []
    Zip::File.open(zip_path) do |zip|
      zip.each { |entry| filenames << entry.name }
    end
    filenames
  end

  def extract_csv_from_zip(zip_path, filename)
    Zip::File.open(zip_path) do |zip|
      entry = zip.find_entry(filename)
      return entry.get_input_stream.read if entry
    end
    ""
  end
end
