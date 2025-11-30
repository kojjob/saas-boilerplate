# frozen_string_literal: true

class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_account

  def show
    # Dashboard page for authenticated users
  end

  private

  def set_account
    @account = current_account || current_user.accounts.first

    unless @account
      redirect_to root_path, alert: "No account found. Please create an account first."
    end
  end
end
