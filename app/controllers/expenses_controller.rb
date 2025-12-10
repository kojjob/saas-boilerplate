# frozen_string_literal: true

class ExpensesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]
  before_action :set_form_options, only: [:new, :create, :edit, :update]

  def index
    @expenses = current_account.expenses.includes(:project, :client).recent

    # Filter by project
    @expenses = @expenses.where(project_id: params[:project_id]) if params[:project_id].present?

    # Filter by client
    @expenses = @expenses.where(client_id: params[:client_id]) if params[:client_id].present?

    # Filter by category
    @expenses = @expenses.by_category(params[:category]) if params[:category].present?

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @expenses = @expenses.where(expense_date: params[:start_date]..params[:end_date])
    elsif params[:period].present?
      case params[:period]
      when "this_week"
        @expenses = @expenses.where(expense_date: Date.current.beginning_of_week..Date.current.end_of_week)
      when "this_month"
        @expenses = @expenses.this_month
      when "this_year"
        @expenses = @expenses.this_year
      end
    end

    # Filter by billable status
    @expenses = @expenses.billable if params[:billable] == "true"

    # Filter by reimbursable status
    @expenses = @expenses.reimbursable if params[:reimbursable] == "true"

    # Search
    @expenses = @expenses.search(params[:q]) if params[:q].present?

    # Stats calculation
    @stats = {
      total_this_month: current_account.expenses.this_month.total_amount || 0,
      total_this_year: current_account.expenses.this_year.total_amount || 0,
      billable_total: current_account.expenses.billable.total_amount || 0,
      reimbursable_total: current_account.expenses.reimbursable.total_amount || 0
    }

    # Category breakdown
    @category_summary = current_account.expenses.this_month.by_category_summary

    @expenses = @expenses.page(params[:page]).per(20) if @expenses.respond_to?(:page)
  end

  def show
  end

  def new
    @expense = current_account.expenses.build
    @expense.project_id = params[:project_id] if params[:project_id].present?
    @expense.client_id = params[:client_id] if params[:client_id].present?
    @expense.expense_date = Date.current
    @expense.currency = current_account.default_currency || "USD"
  end

  def create
    @expense = current_account.expenses.build(expense_params)

    if @expense.save
      respond_to do |format|
        format.html { redirect_to expenses_path, notice: "Expense was successfully created." }
        format.turbo_stream { redirect_to expenses_path, notice: "Expense was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      respond_to do |format|
        format.html { redirect_to expenses_path, notice: "Expense was successfully updated." }
        format.turbo_stream { redirect_to expenses_path, notice: "Expense was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "Expense was successfully deleted."
  end

  def report
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    base_expenses = current_account.expenses.where(expense_date: @start_date..@end_date)

    @expenses = base_expenses.includes(:project, :client).recent
    @category_summary = base_expenses.by_category_summary
    @total_amount = base_expenses.total_amount || 0
    @billable_amount = base_expenses.billable.total_amount || 0
  end

  private

  def set_expense
    @expense = current_account.expenses.find(params[:id])
  end

  def set_form_options
    @projects = current_account.projects.order(:name)
    @clients = current_account.clients.order(:name)
    @categories = Expense.categories.keys.map { |c| [c.humanize, c] }
    @currencies = Currencyable::SUPPORTED_CURRENCIES.map { |code, data| ["#{data[:symbol]} - #{data[:name]} (#{code})", code] }
  end

  def expense_params
    params.require(:expense).permit(
      :description, :amount, :currency, :category, :expense_date,
      :vendor, :billable, :reimbursable, :notes, :project_id, :client_id, :receipt
    )
  end
end
