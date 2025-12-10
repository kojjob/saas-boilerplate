# frozen_string_literal: true

class DashboardController < ApplicationController
  include OnboardingTrackable

  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_account

  def show
    # Initialize onboarding for new users
    current_onboarding
    # Business metrics
    @clients_count = @account.clients.count
    @active_clients = @account.clients.where(status: "active").count
    @projects_count = @account.projects.count
    @active_projects = @account.projects.where(status: %w[active in_progress]).count
    @invoices_count = @account.invoices.count

    # Invoice metrics
    @total_invoiced = @account.invoices.sum(:total_amount)
    @total_paid = @account.invoices.where(status: "paid").sum(:total_amount)
    @total_outstanding = @account.invoices.where(status: %w[sent viewed overdue]).sum(:total_amount)
    @overdue_invoices = @account.invoices.where(status: "overdue")
    @overdue_count = @overdue_invoices.count
    @overdue_amount = @overdue_invoices.sum(:total_amount)

    # Recent activity
    @recent_clients = @account.clients.order(created_at: :desc).limit(5)
    @recent_projects = @account.projects.includes(:client).order(created_at: :desc).limit(5)
    @recent_invoices = @account.invoices.includes(:client).order(created_at: :desc).limit(5)

    # Pending invoices (sent, viewed, or overdue)
    @pending_invoices = @account.invoices.includes(:client)
                                .where(status: %w[sent viewed overdue])
                                .order(due_date: :asc)
                                .limit(5)
  end

  private

  def set_account
    @account = current_account || current_user.accounts.first

    unless @account
      redirect_to root_path, alert: "No account found. Please create an account first."
    end
  end
end
