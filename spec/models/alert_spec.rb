# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alert, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:alertable).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:alert_type) }
    it { should validate_presence_of(:severity) }
    it { should validate_presence_of(:title) }
  end

  describe "enums" do
    it { should define_enum_for(:severity).with_values(info: 0, warning: 1, error: 2, critical: 3) }
    it { should define_enum_for(:status).with_values(pending: 0, sent: 1, failed: 2, acknowledged: 3) }
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".unacknowledged" do
      it "returns alerts that are not acknowledged" do
        pending_alert = create(:alert, account: account, status: :pending)
        sent_alert = create(:alert, account: account, status: :sent)
        acknowledged_alert = create(:alert, account: account, status: :acknowledged)

        expect(Alert.unacknowledged).to include(pending_alert, sent_alert)
        expect(Alert.unacknowledged).not_to include(acknowledged_alert)
      end
    end

    describe ".by_severity" do
      it "returns alerts with the specified severity" do
        info_alert = create(:alert, account: account, severity: :info)
        warning_alert = create(:alert, account: account, severity: :warning)
        critical_alert = create(:alert, account: account, severity: :critical)

        expect(Alert.by_severity(:warning)).to include(warning_alert)
        expect(Alert.by_severity(:warning)).not_to include(info_alert, critical_alert)
      end
    end

    describe ".recent" do
      it "returns alerts from the last 24 hours" do
        recent_alert = create(:alert, account: account, created_at: 1.hour.ago)
        old_alert = create(:alert, account: account, created_at: 2.days.ago)

        expect(Alert.recent).to include(recent_alert)
        expect(Alert.recent).not_to include(old_alert)
      end
    end

    describe ".for_account" do
      it "returns alerts for the specified account" do
        other_account = create(:account)
        account_alert = create(:alert, account: account)
        other_alert = create(:alert, account: other_account)

        expect(Alert.for_account(account)).to include(account_alert)
        expect(Alert.for_account(account)).not_to include(other_alert)
      end
    end
  end

  describe "instance methods" do
    let(:alert) { create(:alert) }

    describe "#acknowledge!" do
      it "changes status to acknowledged" do
        expect { alert.acknowledge! }.to change { alert.status }.to("acknowledged")
      end

      it "sets acknowledged_at timestamp" do
        freeze_time do
          alert.acknowledge!
          expect(alert.acknowledged_at).to eq(Time.current)
        end
      end
    end

    describe "#mark_as_sent!" do
      it "changes status to sent" do
        expect { alert.mark_as_sent! }.to change { alert.status }.to("sent")
      end

      it "sets sent_at timestamp" do
        freeze_time do
          alert.mark_as_sent!
          expect(alert.sent_at).to eq(Time.current)
        end
      end
    end

    describe "#mark_as_failed!" do
      it "changes status to failed" do
        expect { alert.mark_as_failed!("Error message") }.to change { alert.status }.to("failed")
      end

      it "sets error_message" do
        alert.mark_as_failed!("Connection timeout")
        expect(alert.error_message).to eq("Connection timeout")
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:alert)).to be_valid
    end

    it "has valid traits" do
      expect(build(:alert, :info)).to be_valid
      expect(build(:alert, :warning)).to be_valid
      expect(build(:alert, :error)).to be_valid
      expect(build(:alert, :critical)).to be_valid
      expect(build(:alert, :sent)).to be_valid
      expect(build(:alert, :failed)).to be_valid
      expect(build(:alert, :acknowledged)).to be_valid
    end
  end
end
