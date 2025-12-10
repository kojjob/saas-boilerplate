# frozen_string_literal: true

class ProjectsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :archive ]
  before_action :set_clients, only: [ :new, :create, :edit, :update ]

  def index
    @projects = current_account.projects.includes(:client, :time_entries, :material_entries)
                              .search(params[:search])
                              .order(created_at: :desc)
    @projects = @projects.page(params[:page]).per(20) if @projects.respond_to?(:page)
  end

  def show
    @time_entries = @project.time_entries.recent.limit(10)
    @material_entries = @project.material_entries.recent.limit(10)
    @documents = @project.documents.recent.limit(5)
    @invoices = @project.invoices.recent.limit(5)
  end

  def new
    @project = current_account.projects.build
    @project.client_id = params[:client_id] if params[:client_id].present?
  end

  def create
    @project = current_account.projects.build(project_params)

    if @project.save
      track_project_created
      respond_to do |format|
        format.html { redirect_to projects_path, notice: "Project was successfully created." }
        format.turbo_stream { redirect_to projects_path, notice: "Project was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      respond_to do |format|
        format.html { redirect_to projects_path, notice: "Project was successfully updated." }
        format.turbo_stream { redirect_to projects_path, notice: "Project was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @project.invoices.any?
      redirect_to projects_path, alert: "Cannot delete project with existing invoices."
    else
      @project.destroy
      redirect_to projects_path, notice: "Project was successfully deleted."
    end
  end

  def archive
    @project.update(status: :cancelled)
    redirect_to projects_path, notice: "Project was archived."
  end

  private

  def set_project
    @project = current_account.projects.find(params[:id])
  end

  def set_clients
    @clients = current_account.clients.order(:name)
  end

  def project_params
    params.require(:project).permit(
      :name, :client_id, :description, :status, :start_date, :due_date, :end_date,
      :budget, :hourly_rate, :address_line1, :address_line2, :city, :state,
      :postal_code, :notes
    )
  end
end
