# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:account) { create(:account) }
  let(:conversation) do
    Conversation.create!(
      participant_1: user,
      participant_2: other_user,
      account: account
    )
  end

  before do
    create(:membership, user: user, account: account, role: :admin)
    create(:membership, user: other_user, account: account, role: :member)
    sign_in user
  end

  describe "POST /conversations/:conversation_id/messages" do
    let(:valid_params) { { message: { body: "Hello, how are you?" } } }

    it "creates a new message" do
      expect {
        post conversation_messages_path(conversation), params: valid_params
      }.to change(Message, :count).by(1)
    end

    it "assigns the current user as sender" do
      post conversation_messages_path(conversation), params: valid_params

      message = Message.last
      expect(message.sender).to eq(user)
    end

    it "assigns the other participant as recipient" do
      post conversation_messages_path(conversation), params: valid_params

      message = Message.last
      expect(message.recipient).to eq(other_user)
    end

    it "redirects to the conversation on html request" do
      post conversation_messages_path(conversation), params: valid_params

      expect(response).to redirect_to(conversation)
    end

    it "responds with turbo_stream format" do
      post conversation_messages_path(conversation), params: valid_params, as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "renders show with errors for invalid message" do
      post conversation_messages_path(conversation), params: { message: { body: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create message if user is not a participant" do
      other_conversation = Conversation.create!(
        participant_1: create(:user, :confirmed),
        participant_2: create(:user, :confirmed)
      )

      expect {
        post conversation_messages_path(other_conversation), params: valid_params
      }.not_to change(Message, :count)

      expect(response).to redirect_to(conversations_path)
    end
  end

  describe "DELETE /conversations/:conversation_id/messages/:id" do
    let!(:message) do
      Message.create!(
        conversation: conversation,
        sender: user,
        recipient: other_user,
        body: "Test message",
        account: account
      )
    end

    it "deletes the message" do
      expect {
        delete conversation_message_path(conversation, message)
      }.to change(Message, :count).by(-1)
    end

    it "redirects to the conversation on html request" do
      delete conversation_message_path(conversation, message)

      expect(response).to redirect_to(conversation)
    end

    it "responds with turbo_stream format" do
      delete conversation_message_path(conversation, message), as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "does not delete message if user is not the sender" do
      other_message = Message.create!(
        conversation: conversation,
        sender: other_user,
        recipient: user,
        body: "Test message from other user",
        account: account
      )

      expect {
        delete conversation_message_path(conversation, other_message)
      }.not_to change(Message, :count)

      expect(response).to redirect_to(conversation)
    end
  end
end
