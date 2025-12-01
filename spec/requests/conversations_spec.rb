# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:account) { create(:account) }

  before do
    create(:membership, user: user, account: account, role: :admin)
    create(:membership, user: other_user, account: account, role: :member)
    sign_in user
  end

  describe "GET /conversations" do
    it "renders the index page successfully" do
      get conversations_path

      expect(response).to have_http_status(:success)
    end

    it "displays user's conversations" do
      conversation = Conversation.create!(
        participant_1: user,
        participant_2: other_user,
        account: account
      )

      get conversations_path

      expect(response.body).to include(other_user.full_name)
    end
  end

  describe "GET /conversations/:id" do
    let(:conversation) do
      Conversation.create!(
        participant_1: user,
        participant_2: other_user,
        account: account
      )
    end

    it "renders the show page successfully" do
      get conversation_path(conversation)

      expect(response).to have_http_status(:success)
    end

    it "marks unread messages as read" do
      message = Message.create!(
        conversation: conversation,
        sender: other_user,
        recipient: user,
        body: "Hello!",
        account: account
      )

      expect(message.read_at).to be_nil

      get conversation_path(conversation)

      message.reload
      expect(message.read_at).to be_present
    end

    it "redirects if user is not a participant" do
      other_conversation = Conversation.create!(
        participant_1: create(:user, :confirmed),
        participant_2: create(:user, :confirmed)
      )

      get conversation_path(other_conversation)

      expect(response).to redirect_to(conversations_path)
    end
  end

  describe "GET /conversations/new" do
    it "renders the new page successfully" do
      get new_conversation_path

      expect(response).to have_http_status(:success)
    end

    it "displays available recipients" do
      get new_conversation_path

      expect(response.body).to include(other_user.full_name)
    end
  end

  describe "POST /conversations" do
    it "creates a new conversation with a recipient" do
      expect {
        post conversations_path, params: { recipient_id: other_user.id }
      }.to change(Conversation, :count).by(1)

      expect(response).to redirect_to(Conversation.last)
    end

    it "finds existing conversation instead of creating duplicate" do
      existing = Conversation.create!(
        participant_1: user,
        participant_2: other_user,
        account: account
      )

      expect {
        post conversations_path, params: { recipient_id: other_user.id }
      }.not_to change(Conversation, :count)

      expect(response).to redirect_to(existing)
    end

    it "redirects with alert if recipient not found" do
      post conversations_path, params: { recipient_id: 999999 }

      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to eq("User not found.")
    end

    it "redirects with alert if trying to message self" do
      post conversations_path, params: { recipient_id: user.id }

      expect(response).to redirect_to(conversations_path)
      expect(flash[:alert]).to eq("You cannot start a conversation with yourself.")
    end
  end

  describe "DELETE /conversations/:id" do
    let!(:conversation) do
      Conversation.create!(
        participant_1: user,
        participant_2: other_user,
        account: account
      )
    end

    it "deletes the conversation" do
      expect {
        delete conversation_path(conversation)
      }.to change(Conversation, :count).by(-1)

      expect(response).to redirect_to(conversations_path)
    end

    it "does not delete conversation if user is not a participant" do
      other_conversation = Conversation.create!(
        participant_1: create(:user, :confirmed),
        participant_2: create(:user, :confirmed)
      )

      expect {
        delete conversation_path(other_conversation)
      }.not_to change(Conversation, :count)

      expect(response).to redirect_to(conversations_path)
    end
  end
end
