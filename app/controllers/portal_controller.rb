# frozen_string_literal: true

# PortalController provides public-facing client portal functionality
# It inherits directly from ActionController::Base to avoid authentication requirements
class PortalController < ActionController::Base
  before_action :set_client_from_token
  before_action :set_account

  layout "portal"

  # GET /portal/:token
  def dashboard
    @recent_invoices = @client.invoices.order(created_at: :desc).limit(5)
    @recent_projects = @client.projects.order(created_at: :desc).limit(5)
    @recent_estimates = @client.estimates.order(created_at: :desc).limit(5)
  end

  # GET /portal/:token/invoices
  def invoices
    @invoices = @client.invoices.order(created_at: :desc)
  end

  # GET /portal/:token/invoices/:id
  def show_invoice
    @invoice = @client.invoices.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  # GET /portal/:token/invoices/:id/download
  def download_invoice
    @invoice = @client.invoices.find_by!(id: params[:id])
    result = Pdf::InvoicePdfGenerator.call(invoice: @invoice)

    if result.success?
      send_data result.pdf,
                filename: result.filename,
                type: "application/pdf",
                disposition: "attachment"
    else
      render_not_found
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  # GET /portal/:token/estimates
  def estimates
    @estimates = @client.estimates.order(created_at: :desc)
  end

  # GET /portal/:token/estimates/:id
  def show_estimate
    @estimate = @client.estimates.find_by!(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  # GET /portal/:token/estimates/:id/download
  def download_estimate
    @estimate = @client.estimates.find_by!(id: params[:id])
    result = Pdf::EstimatePdfGenerator.call(estimate: @estimate)

    if result.success?
      send_data result.pdf,
                filename: result.filename,
                type: "application/pdf",
                disposition: "attachment"
    else
      render_not_found
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  # GET /portal/:token/projects
  def projects
    @projects = @client.projects.order(created_at: :desc)
  end

  # GET /portal/:token/projects/:id
  def show_project
    @project = @client.projects.find_by!(id: params[:id])
    @invoices = @project.invoices.order(created_at: :desc)
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  private

  def set_client_from_token
    @client = Client.find_by_portal_token(params[:token])
    render_not_found unless @client
  end

  def set_account
    @account = @client&.account
  end

  def render_not_found
    render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
  end
end
