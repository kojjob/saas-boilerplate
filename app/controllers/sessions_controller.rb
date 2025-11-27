# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :set_current_tenant_from_subdomain
  before_action :redirect_if_signed_in, only: [ :new, :create ]

  def new
    # Render sign in form
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to stored_location_or(dashboard_path), notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  def redirect_if_signed_in
    redirect_to dashboard_path, notice: "You are already signed in." if signed_in?
  end
end
