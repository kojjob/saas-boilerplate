# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiToken, type: :model do
  subject { build(:api_token) }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    # Token is auto-generated before validation, so presence is implicitly ensured
    it { should validate_uniqueness_of(:token) }

    it "auto-generates a token before validation" do
      api_token = build(:api_token, token: nil)
      api_token.valid?
      expect(api_token.token).to be_present
    end
  end

  describe "#active?" do
    context "when not revoked and not expired" do
      it "returns true" do
        api_token = create(:api_token)
        expect(api_token.active?).to be true
      end
    end

    context "when revoked" do
      it "returns false" do
        api_token = create(:api_token, revoked_at: Time.current)
        expect(api_token.active?).to be false
      end
    end

    context "when expired" do
      it "returns false" do
        api_token = create(:api_token, expires_at: 1.day.ago)
        expect(api_token.active?).to be false
      end
    end
  end

  describe "#revoke!" do
    it "sets revoked_at timestamp" do
      api_token = create(:api_token)
      expect { api_token.revoke! }.to change { api_token.revoked_at }.from(nil)
    end
  end

  describe ".authenticate" do
    let!(:api_token) { create(:api_token) }

    context "with valid token" do
      it "returns the api token" do
        result = described_class.authenticate(api_token.token)
        expect(result).to eq(api_token)
      end
    end

    context "with revoked token" do
      before { api_token.revoke! }

      it "returns nil" do
        result = described_class.authenticate(api_token.token)
        expect(result).to be_nil
      end
    end

    context "with expired token" do
      before { api_token.update!(expires_at: 1.day.ago) }

      it "returns nil" do
        result = described_class.authenticate(api_token.token)
        expect(result).to be_nil
      end
    end

    context "with invalid token" do
      it "returns nil" do
        result = described_class.authenticate("invalid_token")
        expect(result).to be_nil
      end
    end
  end

  describe ".generate_for" do
    let(:user) { create(:user) }

    it "creates a new API token for the user" do
      expect {
        described_class.generate_for(user)
      }.to change(described_class, :count).by(1)
    end

    it "returns an active token" do
      api_token = described_class.generate_for(user)
      expect(api_token.active?).to be true
    end

    it "sets default expiration to 30 days" do
      api_token = described_class.generate_for(user)
      expect(api_token.expires_at).to be_within(1.minute).of(30.days.from_now)
    end

    it "accepts custom expiration" do
      api_token = described_class.generate_for(user, expires_in: 7.days)
      expect(api_token.expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end
end
