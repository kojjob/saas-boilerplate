# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :confirmed, :admin) }
  let!(:user) { create(:user, :confirmed, first_name: "John", last_name: "Doe") }

  before { sign_in(admin) }

  describe "GET /admin/users" do
    it "returns successful response" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "lists all users" do
      get admin_users_path
      expect(response.body).to include(user.email)
    end

    it "supports searching by email" do
      get admin_users_path, params: { q: user.email }
      expect(response.body).to include(user.email)
    end
  end

  describe "GET /admin/users/:id" do
    it "shows user details" do
      get admin_user_path(user)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "renders edit form" do
      get edit_admin_user_path(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/users/:id" do
    context "with valid params" do
      it "updates the user" do
        patch admin_user_path(user), params: { user: { first_name: "Jane" } }
        expect(response).to redirect_to(admin_user_path(user))
        user.reload
        expect(user.first_name).to eq("Jane")
      end
    end

    context "with invalid params" do
      it "renders edit form with errors" do
        patch admin_user_path(user), params: { user: { email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    context "when user can be deleted" do
      it "soft deletes the user" do
        delete admin_user_path(user)
        expect(response).to redirect_to(admin_users_path)
        expect(user.reload.discarded?).to be true
      end
    end

    context "when trying to delete self" do
      it "prevents deletion" do
        delete admin_user_path(admin)
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:alert]).to be_present
        expect(admin.reload.discarded?).to be false
      end
    end
  end

  describe "POST /admin/users/:id/impersonate" do
    it "impersonates the user" do
      post impersonate_admin_user_path(user)
      expect(response).to redirect_to(root_path)
      expect(session[:admin_user_id]).to eq(admin.id)
    end
  end

  describe "DELETE /admin/users/stop_impersonating" do
    it "stops impersonating and returns to admin" do
      # First impersonate a user
      post impersonate_admin_user_path(user)
      expect(response).to redirect_to(root_path)

      # Then stop impersonating
      delete stop_impersonating_admin_users_path
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
