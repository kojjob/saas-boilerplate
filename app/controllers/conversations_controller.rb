# frozen_string_literal: true

class ConversationsController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :destroy]

  def index
    @conversations = current_user.conversations.recent.includes(:participant_1, :participant_2, :messages)
  end

  def show
    # Mark messages as read when viewing conversation
    @conversation.messages.where(recipient: current_user, read_at: nil).update_all(read_at: Time.current)
    @messages = @conversation.messages.order(created_at: :asc)
    @message = Message.new
  end

  def new
    @conversation = Conversation.new
    @users = available_recipients
  end

  def create
    recipient = User.find_by(id: params[:recipient_id])

    unless recipient
      redirect_to conversations_path, alert: "User not found."
      return
    end

    if recipient == current_user
      redirect_to conversations_path, alert: "You cannot start a conversation with yourself."
      return
    end

    @conversation = Conversation.find_or_create_between(current_user, recipient, account: current_account)
    redirect_to @conversation
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_path, notice: "Conversation deleted."
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to conversations_path, alert: "Conversation not found."
  end

  def available_recipients
    # Get users from the same account(s) excluding current user
    if current_account
      current_account.users.where.not(id: current_user.id)
    else
      User.where.not(id: current_user.id).limit(50)
    end
  end
end
