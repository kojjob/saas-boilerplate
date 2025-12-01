# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "associations" do
    it { should belong_to(:participant_1).class_name("User") }
    it { should belong_to(:participant_2).class_name("User") }
    it { should belong_to(:account).optional }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe "validations" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "validates uniqueness of participant pair" do
      create(:conversation, participant_1: user1, participant_2: user2)
      duplicate = build(:conversation, participant_1: user1, participant_2: user2)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:participant_1_id]).to include("conversation already exists between these users")
    end

    it "validates participants are different users" do
      conversation = build(:conversation, participant_1: user1, participant_2: user1)

      expect(conversation).not_to be_valid
      expect(conversation.errors[:participant_2_id]).to include("can't be the same as participant 1")
    end
  end

  describe "scopes" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    describe ".for_user" do
      it "returns conversations where user is a participant" do
        conversation1 = create(:conversation, participant_1: user1, participant_2: user2)
        conversation2 = create(:conversation, participant_1: user2, participant_2: user3)
        create(:conversation, participant_1: user3, participant_2: create(:user))

        expect(Conversation.for_user(user2)).to include(conversation1, conversation2)
        expect(Conversation.for_user(user2).count).to eq(2)
      end
    end

    describe ".recent" do
      it "returns conversations ordered by updated_at descending" do
        old_convo = create(:conversation, participant_1: user1, participant_2: user2, updated_at: 1.day.ago)
        new_convo = create(:conversation, participant_1: user1, participant_2: user3, updated_at: 1.hour.ago)

        expect(Conversation.recent.first).to eq(new_convo)
        expect(Conversation.recent.last).to eq(old_convo)
      end
    end
  end

  describe ".find_or_create_between" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    context "when conversation exists" do
      it "returns existing conversation" do
        existing = create(:conversation, participant_1: user1, participant_2: user2)
        found = Conversation.find_or_create_between(user1, user2)

        expect(found).to eq(existing)
      end

      it "finds conversation regardless of participant order" do
        existing = create(:conversation, participant_1: user1, participant_2: user2)
        found = Conversation.find_or_create_between(user2, user1)

        expect(found).to eq(existing)
      end
    end

    context "when conversation does not exist" do
      it "creates a new conversation" do
        expect {
          Conversation.find_or_create_between(user1, user2)
        }.to change(Conversation, :count).by(1)
      end
    end
  end

  describe "#other_participant" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    it "returns the other participant" do
      expect(conversation.other_participant(user1)).to eq(user2)
      expect(conversation.other_participant(user2)).to eq(user1)
    end
  end

  describe "#unread_count_for" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    it "returns count of unread messages for user" do
      create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: nil)
      create(:message, conversation: conversation, sender: user1, recipient: user2, read_at: nil)
      create(:message, conversation: conversation, sender: user2, recipient: user1, read_at: Time.current)

      expect(conversation.unread_count_for(user2)).to eq(2)
      expect(conversation.unread_count_for(user1)).to eq(0)
    end
  end

  describe "#last_message" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:conversation) { create(:conversation, participant_1: user1, participant_2: user2) }

    it "returns the most recent message" do
      create(:message, conversation: conversation, sender: user1, recipient: user2, created_at: 1.hour.ago)
      last = create(:message, conversation: conversation, sender: user2, recipient: user1, created_at: 1.minute.ago)

      expect(conversation.last_message).to eq(last)
    end
  end
end
