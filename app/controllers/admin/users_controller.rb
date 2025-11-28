# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    include Pagy::Backend

    before_action :set_user, only: [ :show, :edit, :update, :destroy, :impersonate ]

    def index
      users = User.kept.order(created_at: :desc)
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
      session[:admin_user_id] = current_user.id
      sign_in(@user)
      redirect_to root_path, notice: "You are now impersonating #{@user.full_name}."
    end

    def stop_impersonating
      admin = User.find_by(id: session[:admin_user_id])
      session.delete(:admin_user_id)

      if admin
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
