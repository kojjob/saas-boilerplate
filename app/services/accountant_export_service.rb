# frozen_string_literal: true

require "zip"
require "csv"

# Service to generate year-end accountant export bundle
# Creates a ZIP file containing CSVs for invoices, time entries,
# materials, and a profit/loss summary
class AccountantExportService
  attr_reader :account, :year

  def initialize(account, year: Date.current.year)
    @account = account
    @year = year
    @zip_path = nil
  end

  def generate_bundle
    temp_dir = Rails.root.join("tmp", "exports", SecureRandom.uuid)
    FileUtils.mkdir_p(temp_dir)

    begin
      # Generate CSV files
      generate_invoices_csv(temp_dir)
      generate_time_entries_csv(temp_dir)
      generate_materials_csv(temp_dir)
      generate_profit_loss_csv(temp_dir)

      # Create ZIP file
      @zip_path = create_zip_file(temp_dir)

      ApplicationService::Result.new(
        success: true,
        data: { zip_path: @zip_path, filename: zip_filename }
      )
    rescue StandardError => e
      ApplicationService::Result.new(
        success: false,
        error: "Failed to generate export bundle: #{e.message}"
      )
    ensure
      # Clean up temp directory (but not the zip file)
      FileUtils.rm_rf(temp_dir)
    end
  end

  def cleanup
    FileUtils.rm_f(@zip_path) if @zip_path && File.exist?(@zip_path)
    @zip_path = nil
  end

  private

  def generate_invoices_csv(temp_dir)
    csv_path = File.join(temp_dir, "invoices.csv")

    CSV.open(csv_path, "wb") do |csv|
      csv << invoices_headers

      year_invoices.find_each do |invoice|
        csv << invoices_row(invoice)
      end
    end
  end

  def generate_time_entries_csv(temp_dir)
    csv_path = File.join(temp_dir, "time_entries.csv")

    CSV.open(csv_path, "wb") do |csv|
      csv << time_entries_headers

      year_time_entries.find_each do |entry|
        csv << time_entries_row(entry)
      end
    end
  end

  def generate_materials_csv(temp_dir)
    csv_path = File.join(temp_dir, "materials.csv")

    CSV.open(csv_path, "wb") do |csv|
      csv << materials_headers

      year_material_entries.find_each do |entry|
        csv << materials_row(entry)
      end
    end
  end

  def generate_profit_loss_csv(temp_dir)
    csv_path = File.join(temp_dir, "profit_loss_summary.csv")

    CSV.open(csv_path, "wb") do |csv|
      csv << [ "Category", "Amount" ]
      csv << [ "Total Revenue", total_revenue ]
      csv << [ "Total Costs", total_costs ]
      csv << [ "Net Profit", net_profit ]
    end
  end

  def create_zip_file(temp_dir)
    zip_path = Rails.root.join("tmp", "exports", "#{zip_filename}.zip")
    FileUtils.mkdir_p(File.dirname(zip_path))

    # Remove existing ZIP file if present to ensure clean state
    FileUtils.rm_f(zip_path) if File.exist?(zip_path)

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      Dir.glob(File.join(temp_dir, "*")).each do |file|
        zipfile.add(File.basename(file), file)
      end
    end

    zip_path.to_s
  end

  def zip_filename
    "accountant_export_#{account.id}_#{year}"
  end

  # Invoice helpers
  def year_invoices
    account.invoices
      .where(issue_date: year_start..year_end)
      .includes(:client)
      .order(:issue_date)
  end

  def invoices_headers
    [
      "Invoice Number",
      "Client",
      "Issue Date",
      "Due Date",
      "Status",
      "Subtotal",
      "Tax",
      "Total",
      "Paid At"
    ]
  end

  def invoices_row(invoice)
    [
      invoice.invoice_number,
      invoice.client&.name,
      invoice.issue_date,
      invoice.due_date,
      invoice.status,
      invoice.subtotal,
      invoice.tax_amount,
      invoice.total_amount,
      invoice.paid_at
    ]
  end

  # Time entries helpers
  def year_time_entries
    account.time_entries
      .where(date: year_start..year_end)
      .includes(:project, :user)
      .order(:date)
  end

  def time_entries_headers
    [
      "Date",
      "Project",
      "User",
      "Description",
      "Hours",
      "Hourly Rate",
      "Total"
    ]
  end

  def time_entries_row(entry)
    [
      entry.date,
      entry.project&.name,
      entry.user&.full_name,
      entry.description,
      entry.hours,
      entry.hourly_rate,
      entry.total_amount
    ]
  end

  # Material entries helpers
  def year_material_entries
    account.material_entries
      .where(date: year_start..year_end)
      .includes(:project, :user)
      .order(:date)
  end

  def materials_headers
    [
      "Date",
      "Material",
      "Project",
      "User",
      "Quantity",
      "Unit Cost",
      "Total"
    ]
  end

  def materials_row(entry)
    [
      entry.date,
      entry.name,
      entry.project&.name,
      entry.user&.full_name,
      entry.quantity,
      entry.unit_cost,
      entry.total_amount
    ]
  end

  # Profit/Loss calculations
  def total_revenue
    account.invoices
      .where(issue_date: year_start..year_end)
      .where(status: :paid)
      .sum(:total_amount)
  end

  def total_costs
    account.material_entries
      .where(date: year_start..year_end)
      .sum(:total_amount)
  end

  def net_profit
    total_revenue - total_costs
  end

  def year_start
    Date.new(year, 1, 1)
  end

  def year_end
    Date.new(year, 12, 31)
  end
end
