# frozen_string_literal: true

class InvoicesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :send_invoice, :mark_paid, :mark_cancelled ]
  before_action :set_form_data, only: [ :new, :create, :edit, :update ]

  def index
    @invoices = current_account.invoices.includes(:client, :project)
                               .search(params[:search])
                               .order(issue_date: :desc)

    if params[:status].present? && params[:status] != "all"
      @invoices = @invoices.where(status: params[:status])
    end

    @invoices = @invoices.page(params[:page]).per(20) if @invoices.respond_to?(:page)

    # Stats for dashboard cards
    @stats = {
      total_outstanding: current_account.invoices.unpaid.sum(:total_amount),
      total_overdue: current_account.invoices.past_due.sum(:total_amount),
      paid_this_month: current_account.invoices.with_status_paid
                                      .where(paid_at: Time.current.beginning_of_month..Time.current.end_of_month)
                                      .sum(:total_amount),
      due_soon_count: current_account.invoices.due_soon.count
    }
  end

  def show
  end

  def new
    @invoice = current_account.invoices.build
    @invoice.client_id = params[:client_id] if params[:client_id].present?
    @invoice.project_id = params[:project_id] if params[:project_id].present?
    # Build one line item to start
    @invoice.line_items.build
  end

  def create
    @invoice = current_account.invoices.build(invoice_params)

    if @invoice.save
      respond_to do |format|
        format.html { redirect_to invoices_path, notice: "Invoice was successfully created." }
        format.turbo_stream { redirect_to invoices_path, notice: "Invoice was successfully created." }
      end
    else
      @invoice.line_items.build if @invoice.line_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @invoice.line_items.build if @invoice.line_items.empty?
  end

  def update
    if @invoice.update(invoice_params)
      respond_to do |format|
        format.html { redirect_to invoices_path, notice: "Invoice was successfully updated." }
        format.turbo_stream { redirect_to invoices_path, notice: "Invoice was successfully updated." }
      end
    else
      @invoice.line_items.build if @invoice.line_items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.draft? || @invoice.cancelled?
      @invoice.destroy
      redirect_to invoices_path, notice: "Invoice was successfully deleted."
    else
      redirect_to invoices_path, alert: "Only draft or cancelled invoices can be deleted."
    end
  end

  def send_invoice
    if @invoice.draft?
      @invoice.mark_as_sent!
      redirect_to invoices_path, notice: "Invoice was marked as sent."
    else
      redirect_to invoices_path, alert: "Invoice has already been sent."
    end
  end

  def mark_paid
    if @invoice.unpaid?
      @invoice.mark_as_paid!(
        payment_date: params[:payment_date].presence || Time.current,
        payment_method: params[:payment_method],
        payment_reference: params[:payment_reference]
      )
      respond_to do |format|
        format.html { redirect_to invoices_path, notice: "Invoice was marked as paid." }
        format.turbo_stream { redirect_to invoices_path, notice: "Invoice was marked as paid." }
      end
    else
      redirect_to invoices_path, alert: "Invoice cannot be marked as paid."
    end
  end

  def mark_cancelled
    if !@invoice.paid?
      @invoice.update!(status: :cancelled)
      redirect_to invoices_path, notice: "Invoice was cancelled."
    else
      redirect_to invoices_path, alert: "Paid invoices cannot be cancelled."
    end
  end

  private

  def set_invoice
    @invoice = current_account.invoices.find(params[:id])
  end

  def set_form_data
    @clients = current_account.clients.order(:name)
    @projects = current_account.projects.order(:name)
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id, :project_id, :invoice_number, :issue_date, :due_date,
      :tax_rate, :discount_amount, :notes, :terms, :status,
      line_items_attributes: [ :id, :description, :quantity, :unit_price, :position, :_destroy ]
    )
  end
end
