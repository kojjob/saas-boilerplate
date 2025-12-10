# frozen_string_literal: true

class RecurringInvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recurring_invoice, only: [:show, :edit, :update, :destroy, :pause, :resume, :cancel, :generate_now]

  def index
    @recurring_invoices = current_account.recurring_invoices.includes(:client).order(created_at: :desc)
  end

  def show
    @generated_invoices = @recurring_invoice.invoices.order(created_at: :desc).limit(10)
  end

  def new
    @recurring_invoice = current_account.recurring_invoices.build(
      start_date: Date.current,
      payment_terms: 30,
      currency: current_account.default_currency || "USD"
    )
    @recurring_invoice.line_items.build
  end

  def create
    @recurring_invoice = current_account.recurring_invoices.build(recurring_invoice_params)

    if @recurring_invoice.save
      redirect_to @recurring_invoice, notice: "Recurring invoice created successfully."
    else
      @recurring_invoice.line_items.build if @recurring_invoice.line_items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @recurring_invoice.line_items.build if @recurring_invoice.line_items.empty?
  end

  def update
    if @recurring_invoice.update(recurring_invoice_params)
      redirect_to @recurring_invoice, notice: "Recurring invoice updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recurring_invoice.destroy
    redirect_to recurring_invoices_path, notice: "Recurring invoice deleted successfully."
  end

  def pause
    @recurring_invoice.pause!
    redirect_to @recurring_invoice, notice: "Recurring invoice paused."
  end

  def resume
    @recurring_invoice.resume!
    redirect_to @recurring_invoice, notice: "Recurring invoice resumed."
  end

  def cancel
    @recurring_invoice.cancel!
    redirect_to @recurring_invoice, notice: "Recurring invoice cancelled."
  end

  def generate_now
    service = RecurringInvoiceService.new(@recurring_invoice)
    invoice = service.generate_invoice!
    redirect_to invoice, notice: "Invoice generated successfully."
  rescue RecurringInvoiceService::CannotGenerateError => e
    redirect_to @recurring_invoice, alert: e.message
  end

  private

  def set_recurring_invoice
    @recurring_invoice = current_account.recurring_invoices.find(params[:id])
  end

  def recurring_invoice_params
    params.require(:recurring_invoice).permit(
      :name, :client_id, :project_id, :frequency, :start_date, :end_date,
      :payment_terms, :currency, :tax_rate, :notes,
      :auto_send, :email_subject, :email_body, :occurrences_limit,
      line_items_attributes: [:id, :description, :quantity, :unit_price, :position, :_destroy]
    )
  end
end
