# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    include Pagy::Backend

    before_action :set_user, only: [ :show, :edit, :update, :destroy, :impersonate ]

    def index
      users = User.kept.includes(:memberships, :accounts).order(created_at: :desc)
      users = users.where("email ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      @pagy, @users = pagy(users, limit: 25)
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete yourself."
        return
      end

      @user.discard
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end

    def impersonate
      # Audit trail for impersonation start
      Rails.logger.info("[ADMIN IMPERSONATION] #{current_user.email} (ID: #{current_user.id}) started impersonating #{@user.email} (ID: #{@user.id})")

      Audited::Audit.create!(
        auditable: @user,
        action: "impersonate_started",
        user: current_user,
        comment: "Admin #{current_user.email} started impersonating user",
        remote_address: request.remote_ip,
        request_uuid: request.uuid
      )

      session[:admin_user_id] = current_user.id
      session[:impersonation_started_at] = Time.current.to_i
      sign_in(@user)
      redirect_to root_path, notice: "You are now impersonating #{@user.full_name}."
    end

    def stop_impersonating
      admin = User.find_by(id: session[:admin_user_id])
      impersonated_user = current_user
      impersonation_duration = session[:impersonation_started_at] ? Time.current.to_i - session[:impersonation_started_at].to_i : 0

      session.delete(:admin_user_id)
      session.delete(:impersonation_started_at)

      if admin
        # Audit trail for impersonation end
        Rails.logger.info("[ADMIN IMPERSONATION] #{admin.email} (ID: #{admin.id}) stopped impersonating #{impersonated_user.email} (ID: #{impersonated_user.id}) after #{impersonation_duration} seconds")

        Audited::Audit.create!(
          auditable: impersonated_user,
          action: "impersonate_ended",
          user: admin,
          comment: "Admin #{admin.email} stopped impersonating user after #{impersonation_duration} seconds",
          remote_address: request.remote_ip,
          request_uuid: request.uuid
        )

        sign_in(admin)
        redirect_to admin_root_path, notice: "You have stopped impersonating."
      else
        redirect_to root_path
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :site_admin)
    end

    def sign_in(user)
      session[:user_id] = user.id
    end
  end
end
