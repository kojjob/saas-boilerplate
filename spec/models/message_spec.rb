# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  describe "associations" do
    it { should belong_to(:sender).class_name("User") }
    it { should belong_to(:recipient).class_name("User") }
    it { should belong_to(:account).optional }
    it { should belong_to(:conversation) }
  end

  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  describe "scopes" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    describe ".recent" do
      it "returns messages in descending order by created_at" do
        old_message = create(:message, conversation: conversation, sender: user1, recipient: user2, created_at: 1.day.ago)
        new_message = create(:message, conversation: conversation, sender: user2, recipient: user1, created_at: 1.hour.ago)

        expect(Message.recent).to eq([new_message, old_message])
      end
    end

    describe ".unread" do
      it "returns only unread messages" do
        unread = create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: nil)
        read = create(:message, conversation: conversation, sender: user2, recipient: user1, read_at: Time.current)

        expect(Message.unread).to include(unread)
        expect(Message.unread).not_to include(read)
      end
    end
  end

  describe "#mark_as_read!" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }
    let(:message) { create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: nil) }

    it "sets read_at to current time" do
      freeze_time do
        message.mark_as_read!
        expect(message.read_at).to eq(Time.current)
      end
    end
  end

  describe "#unread?" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    context "when read_at is nil" do
      let(:message) { create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: nil) }

      it "returns true" do
        expect(message.unread?).to be true
      end
    end

    context "when read_at is set" do
      let(:message) { create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: Time.current) }

      it "returns false" do
        expect(message.unread?).to be false
      end
    end
  end

  describe "broadcasting" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    it "broadcasts to conversation channel after create" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "conversation_#{conversation.id}",
        hash_including(:message)
      )

      create(:message, conversation: conversation, sender: user1, recipient: user2)
    end
  end
end
