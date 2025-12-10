# frozen_string_literal: true

class ExportsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :require_account
  before_action :authorize_export
  before_action :set_export_service, only: [:create]

  def new
    @available_years = available_export_years
    @selected_year = params[:year] || Date.current.year
  end

  def create
    result = @export_service.generate_bundle

    if result.success?
      # Use send_data instead of send_file to ensure file is read before cleanup
      zip_data = File.binread(result.data[:zip_path])
      send_data zip_data,
        filename: "#{result.data[:filename]}.zip",
        type: "application/zip",
        disposition: "attachment"
    else
      flash[:alert] = result.error
      redirect_to new_export_path
    end
  ensure
    @export_service&.cleanup
  end

  private

  def set_export_service
    year = params[:year]&.to_i || Date.current.year
    @export_service = AccountantExportService.new(current_account, year: year)
  end

  def available_export_years
    # Get years for which we have data (invoices or material entries)
    invoice_years = current_account.invoices.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM issue_date)::integer"))
    material_years = current_account.material_entries.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM date)::integer"))
    time_entry_years = current_account.time_entries.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM date)::integer"))

    years = (invoice_years + material_years + time_entry_years).uniq.sort.reverse
    years.presence || [Date.current.year]
  end

  def authorize_export
    authorize :export, policy_class: ExportPolicy
  end

  def require_account
    unless current_account
      redirect_to root_path, alert: "Please select an account first."
    end
  end
end
