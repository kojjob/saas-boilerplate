# frozen_string_literal: true

class ClientsController < ApplicationController
  include OnboardingTrackable

  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_client, only: [ :show, :edit, :update, :destroy, :projects, :invoices ]

  def index
    @clients = current_account.clients.includes(:projects, :invoices)
                              .search(params[:search])
                              .order(created_at: :desc)
    @clients = @clients.page(params[:page]).per(20) if @clients.respond_to?(:page)
  end

  def show
    @recent_projects = @client.projects.recent.limit(5)
    @recent_invoices = @client.invoices.recent.limit(5)
  end

  def new
    @client = current_account.clients.build
  end

  def create
    @client = current_account.clients.build(client_params)

    if @client.save
      track_onboarding_step(:created_client)
      respond_to do |format|
        format.html { redirect_to clients_path, notice: "Client was successfully created." }
        format.turbo_stream { redirect_to clients_path, notice: "Client was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      respond_to do |format|
        format.html { redirect_to clients_path, notice: "Client was successfully updated." }
        format.turbo_stream { redirect_to clients_path, notice: "Client was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.projects.any? || @client.invoices.any?
      redirect_to clients_path, alert: "Cannot delete client with existing projects or invoices."
    else
      @client.destroy
      redirect_to clients_path, notice: "Client was successfully deleted."
    end
  end

  def projects
    @projects = @client.projects.includes(:time_entries, :material_entries).recent
    @projects = @projects.page(params[:page]).per(20) if @projects.respond_to?(:page)
  end

  def invoices
    @invoices = @client.invoices.includes(:line_items).recent
    @invoices = @invoices.page(params[:page]).per(20) if @invoices.respond_to?(:page)
  end

  private

  def set_client
    @client = current_account.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :name, :company, :email, :phone, :address_line1, :address_line2,
      :city, :state, :postal_code, :country, :notes
    )
  end
end
