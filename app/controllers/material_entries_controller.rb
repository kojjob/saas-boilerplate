# frozen_string_literal: true

class MaterialEntriesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_material_entry, only: [ :show, :edit, :update, :destroy, :mark_invoiced ]
  before_action :set_projects, only: [ :new, :create, :edit, :update ]

  def index
    @material_entries = current_account.material_entries.includes(:project, :user)
                                       .recent

    # Filter by project
    if params[:project_id].present?
      @material_entries = @material_entries.where(project_id: params[:project_id])
    end

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @material_entries = @material_entries.for_date_range(params[:start_date], params[:end_date])
    elsif params[:period].present?
      case params[:period]
      when "this_week"
        @material_entries = @material_entries.this_week
      when "this_month"
        @material_entries = @material_entries.this_month
      end
    end

    # Filter by billable status
    if params[:billable].present?
      @material_entries = params[:billable] == "true" ? @material_entries.billable : @material_entries.non_billable
    end

    # Filter by invoiced status
    if params[:invoiced].present?
      @material_entries = params[:invoiced] == "true" ? @material_entries.invoiced : @material_entries.not_invoiced
    end

    # Stats calculation
    @stats = {
      total_this_month: current_account.material_entries.this_month.sum(:total_amount),
      billable_this_month: current_account.material_entries.this_month.billable.sum(:total_amount),
      uninvoiced_total: current_account.material_entries.billable.not_invoiced.sum(:total_amount),
      entries_count: current_account.material_entries.this_month.count
    }

    @material_entries = @material_entries.page(params[:page]).per(20) if @material_entries.respond_to?(:page)
  end

  def show
  end

  def new
    @material_entry = current_account.material_entries.build
    @material_entry.project_id = params[:project_id] if params[:project_id].present?
    @material_entry.date = Date.current
    @material_entry.billable = true
    @material_entry.quantity = 1
    @material_entry.markup_percentage = 0
  end

  def create
    @material_entry = current_account.material_entries.build(material_entry_params)
    @material_entry.user = current_user

    if @material_entry.save
      respond_to do |format|
        format.html { redirect_to material_entries_path, notice: "Material entry was successfully created." }
        format.turbo_stream { redirect_to material_entries_path, notice: "Material entry was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @material_entry.update(material_entry_params)
      respond_to do |format|
        format.html { redirect_to material_entries_path, notice: "Material entry was successfully updated." }
        format.turbo_stream { redirect_to material_entries_path, notice: "Material entry was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @material_entry.destroy
    redirect_to material_entries_path, notice: "Material entry was successfully deleted."
  end

  def mark_invoiced
    @material_entry.mark_as_invoiced!
    redirect_to material_entries_path, notice: "Material entry marked as invoiced."
  end

  def report
    # Default to this month if no date range specified
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    base_entries = current_account.material_entries.for_date_range(@start_date, @end_date)

    # For display
    @material_entries = base_entries.includes(:project, :user).recent

    # Group by project for summary - use reorder to avoid ORDER BY conflict
    @project_summary = base_entries.reorder(nil).group(:project_id).sum(:total_amount)
    @total_amount = base_entries.sum(:total_amount)
    @total_billable = base_entries.billable.sum(:total_amount)
  end

  private

  def set_material_entry
    @material_entry = current_account.material_entries.find(params[:id])
  end

  def set_projects
    @projects = current_account.projects.active.order(:name)
  end

  def material_entry_params
    params.require(:material_entry).permit(:project_id, :date, :name, :description, :quantity, :unit, :unit_cost, :billable, :markup_percentage)
  end
end
