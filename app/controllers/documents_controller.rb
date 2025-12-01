# frozen_string_literal: true

class DocumentsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_document, only: [ :show, :edit, :update, :destroy, :download ]
  before_action :set_projects, only: [ :new, :create, :edit, :update ]

  def index
    @documents = current_account.documents.includes(:project, :uploaded_by, file_attachment: :blob)
                                .search(params[:search])
                                .order(created_at: :desc)

    if params[:category].present? && params[:category] != "all"
      @documents = @documents.where(category: params[:category])
    end

    if params[:project_id].present?
      @documents = @documents.where(project_id: params[:project_id])
    end

    @documents = @documents.page(params[:page]).per(20) if @documents.respond_to?(:page)
  end

  def show
  end

  def new
    @document = current_account.documents.build
    @document.project_id = params[:project_id] if params[:project_id].present?
  end

  def create
    @document = current_account.documents.build(document_params)
    @document.uploaded_by = current_user

    if @document.save
      respond_to do |format|
        format.html { redirect_to documents_path, notice: "Document was successfully uploaded." }
        format.turbo_stream { redirect_to documents_path, notice: "Document was successfully uploaded." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document.update(document_params)
      respond_to do |format|
        format.html { redirect_to documents_path, notice: "Document was successfully updated." }
        format.turbo_stream { redirect_to documents_path, notice: "Document was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to documents_path, notice: "Document was successfully deleted."
  end

  def download
    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    else
      redirect_to documents_path, alert: "File not found."
    end
  end

  private

  def set_document
    @document = current_account.documents.find(params[:id])
  end

  def set_projects
    @projects = current_account.projects.order(:name)
  end

  def document_params
    params.require(:document).permit(:name, :description, :category, :project_id, :file)
  end
end
