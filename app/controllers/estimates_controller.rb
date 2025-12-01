# frozen_string_literal: true

class EstimatesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_estimate, only: [ :show, :edit, :update, :destroy, :send_estimate, :accept, :decline, :convert_to_invoice, :preview, :download ]
  before_action :set_form_data, only: [ :new, :create, :edit, :update ]

  def index
    @estimates = current_account.estimates.includes(:client, :project)
                                .search(params[:search])
                                .order(issue_date: :desc)

    if params[:status].present? && params[:status] != "all"
      @estimates = @estimates.where(status: params[:status])
    end

    @estimates = @estimates.page(params[:page]).per(20) if @estimates.respond_to?(:page)

    # Stats for dashboard cards
    @stats = {
      total_pending: current_account.estimates.pending.sum(:total_amount),
      accepted_this_month: current_account.estimates.where(status: :accepted)
                                          .where(accepted_at: Time.current.beginning_of_month..Time.current.end_of_month)
                                          .sum(:total_amount),
      expiring_soon_count: current_account.estimates.expiring_soon.count,
      conversion_rate: calculate_conversion_rate
    }
  end

  def show
  end

  def new
    @estimate = current_account.estimates.build
    @estimate.client_id = params[:client_id] if params[:client_id].present?
    @estimate.project_id = params[:project_id] if params[:project_id].present?
    # Build one line item to start
    @estimate.line_items.build
  end

  def create
    @estimate = current_account.estimates.build(estimate_params)

    if @estimate.save
      respond_to do |format|
        format.html { redirect_to estimates_path, notice: "Estimate was successfully created." }
        format.turbo_stream { redirect_to estimates_path, notice: "Estimate was successfully created." }
      end
    else
      @estimate.line_items.build if @estimate.line_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @estimate.line_items.build if @estimate.line_items.empty?
  end

  def update
    if @estimate.update(estimate_params)
      respond_to do |format|
        format.html { redirect_to estimates_path, notice: "Estimate was successfully updated." }
        format.turbo_stream { redirect_to estimates_path, notice: "Estimate was successfully updated." }
      end
    else
      @estimate.line_items.build if @estimate.line_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @estimate.draft? || @estimate.declined?
      @estimate.destroy
      respond_to do |format|
        format.html { redirect_to estimates_path, notice: "Estimate was successfully deleted." }
        format.turbo_stream { redirect_to estimates_path, notice: "Estimate was successfully deleted." }
      end
    else
      respond_to do |format|
        format.html { redirect_to estimates_path, alert: "Only draft or declined estimates can be deleted." }
        format.turbo_stream { redirect_to estimates_path, alert: "Only draft or declined estimates can be deleted." }
      end
    end
  end

  def send_estimate
    if @estimate.draft?
      # TODO: Add EstimateMailer for sending estimates
      @estimate.mark_as_sent!
      redirect_to estimates_path, notice: "Estimate was sent to #{@estimate.client.email}."
    else
      redirect_to estimates_path, alert: "Estimate has already been sent."
    end
  end

  def accept
    if @estimate.sent? || @estimate.viewed?
      @estimate.mark_as_accepted!
      redirect_to estimates_path, notice: "Estimate was marked as accepted."
    else
      redirect_to estimates_path, alert: "Estimate cannot be accepted in current status."
    end
  end

  def decline
    if @estimate.sent? || @estimate.viewed?
      @estimate.mark_as_declined!
      redirect_to estimates_path, notice: "Estimate was marked as declined."
    else
      redirect_to estimates_path, alert: "Estimate cannot be declined in current status."
    end
  end

  def convert_to_invoice
    if @estimate.can_convert?
      invoice = @estimate.convert_to_invoice!
      redirect_to invoice_path(invoice), notice: "Estimate was converted to invoice successfully."
    else
      redirect_to estimates_path, alert: "Estimate must be accepted and not already converted."
    end
  end

  def preview
    render layout: "estimate_preview"
  end

  def download
    # TODO: Implement EstimatePdfGenerator similar to InvoicePdfGenerator
    redirect_to estimate_path(@estimate), alert: "PDF download not yet implemented."
  end

  private

  def set_estimate
    @estimate = current_account.estimates.find(params[:id])
  end

  def set_form_data
    @clients = current_account.clients.order(:name)
    @projects = current_account.projects.order(:name)
  end

  def estimate_params
    params.require(:estimate).permit(
      :client_id, :project_id, :estimate_number, :issue_date, :valid_until,
      :tax_rate, :discount_amount, :notes, :terms, :status,
      line_items_attributes: [ :id, :description, :quantity, :unit_price, :position, :_destroy ]
    )
  end

  def calculate_conversion_rate
    total_estimates = current_account.estimates.where.not(status: :draft).count
    return 0 if total_estimates.zero?

    converted_count = current_account.estimates.where(status: :converted).count
    ((converted_count.to_f / total_estimates) * 100).round(1)
  end
end
