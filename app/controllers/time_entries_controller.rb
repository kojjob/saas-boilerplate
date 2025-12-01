# frozen_string_literal: true

class TimeEntriesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_time_entry, only: [ :show, :edit, :update, :destroy, :mark_invoiced ]
  before_action :set_projects, only: [ :new, :create, :edit, :update ]

  def index
    @time_entries = current_account.time_entries.includes(:project, :user)
                                   .recent

    # Filter by project
    if params[:project_id].present?
      @time_entries = @time_entries.where(project_id: params[:project_id])
    end

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @time_entries = @time_entries.for_date_range(params[:start_date], params[:end_date])
    elsif params[:period].present?
      case params[:period]
      when "this_week"
        @time_entries = @time_entries.this_week
      when "this_month"
        @time_entries = @time_entries.this_month
      end
    end

    # Filter by billable status
    if params[:billable].present?
      @time_entries = params[:billable] == "true" ? @time_entries.billable : @time_entries.non_billable
    end

    # Filter by invoiced status
    if params[:invoiced].present?
      @time_entries = params[:invoiced] == "true" ? @time_entries.invoiced : @time_entries.not_invoiced
    end

    # Stats calculation
    @stats = {
      total_hours_this_week: current_account.time_entries.this_week.sum(:hours),
      total_hours_this_month: current_account.time_entries.this_month.sum(:hours),
      billable_this_month: current_account.time_entries.this_month.billable.sum(:total_amount),
      uninvoiced_total: current_account.time_entries.billable.not_invoiced.sum(:total_amount)
    }

    @time_entries = @time_entries.page(params[:page]).per(20) if @time_entries.respond_to?(:page)
  end

  def show
  end

  def new
    @time_entry = current_account.time_entries.build
    @time_entry.project_id = params[:project_id] if params[:project_id].present?
    @time_entry.date = Date.current
    @time_entry.billable = true
  end

  def create
    @time_entry = current_account.time_entries.build(time_entry_params)
    @time_entry.user = current_user

    if @time_entry.save
      respond_to do |format|
        format.html { redirect_to time_entries_path, notice: "Time entry was successfully created." }
        format.turbo_stream { redirect_to time_entries_path, notice: "Time entry was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @time_entry.update(time_entry_params)
      respond_to do |format|
        format.html { redirect_to time_entries_path, notice: "Time entry was successfully updated." }
        format.turbo_stream { redirect_to time_entries_path, notice: "Time entry was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_entry.destroy
    redirect_to time_entries_path, notice: "Time entry was successfully deleted."
  end

  def mark_invoiced
    @time_entry.mark_as_invoiced!
    redirect_to time_entries_path, notice: "Time entry marked as invoiced."
  end

  def report
    # Default to this month if no date range specified
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    base_entries = current_account.time_entries.for_date_range(@start_date, @end_date)

    # For display
    @time_entries = base_entries.includes(:project, :user).recent

    # Group by project for summary - use unscoped query to avoid ORDER BY conflict
    @project_summary = base_entries.reorder(nil).group(:project_id).sum(:hours)
    @total_hours = base_entries.sum(:hours)
    @total_billable = base_entries.billable.sum(:total_amount)
  end

  private

  def set_time_entry
    @time_entry = current_account.time_entries.find(params[:id])
  end

  def set_projects
    @projects = current_account.projects.active.order(:name)
  end

  def time_entry_params
    params.require(:time_entry).permit(:project_id, :date, :hours, :description, :billable, :hourly_rate)
  end
end
