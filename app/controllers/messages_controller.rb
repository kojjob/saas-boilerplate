# frozen_string_literal: true

class MessagesController < ApplicationController
  layout "dashboard"

  before_action :authenticate_user!
  before_action :set_conversation
  before_action :set_message, only: [:destroy]

  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user
    @message.recipient = @conversation.other_participant(current_user)
    @message.account = current_account

    if @message.save
      respond_to do |format|
        format.html { redirect_to @conversation }
        format.turbo_stream
      end
    else
      @messages = @conversation.messages.order(created_at: :asc)
      render "conversations/show", status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy

    respond_to do |format|
      format.html { redirect_to @conversation, notice: "Message deleted." }
      format.turbo_stream
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to conversations_path, alert: "Conversation not found."
  end

  def set_message
    @message = @conversation.messages.where(sender: current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to @conversation, alert: "Message not found."
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
