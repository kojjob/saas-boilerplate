# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnboardingProgress, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:onboarding_progress) }

    it { should validate_uniqueness_of(:user_id) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns non-dismissed and non-completed progresses" do
        active = create(:onboarding_progress)
        dismissed = create(:onboarding_progress, :dismissed)
        completed = create(:onboarding_progress, :completed)

        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(dismissed)
        expect(described_class.active).not_to include(completed)
      end
    end

    describe ".completed" do
      it "returns only completed progresses" do
        active = create(:onboarding_progress)
        completed = create(:onboarding_progress, :completed)

        expect(described_class.completed).to include(completed)
        expect(described_class.completed).not_to include(active)
      end
    end
  end

  describe "step tracking methods" do
    let(:onboarding) { create(:onboarding_progress) }

    describe "#complete_step!" do
      it "marks the client step as completed" do
        expect { onboarding.complete_step!(:created_client) }
          .to change { onboarding.created_client_at }.from(nil)
        expect(onboarding.created_client_at).to be_within(1.second).of(Time.current)
      end

      it "marks the project step as completed" do
        expect { onboarding.complete_step!(:created_project) }
          .to change { onboarding.created_project_at }.from(nil)
      end

      it "marks the invoice step as completed" do
        expect { onboarding.complete_step!(:created_invoice) }
          .to change { onboarding.created_invoice_at }.from(nil)
      end

      it "marks the sent_invoice step as completed" do
        expect { onboarding.complete_step!(:sent_invoice) }
          .to change { onboarding.sent_invoice_at }.from(nil)
      end

      it "does not overwrite an already completed step" do
        original_time = 2.days.ago
        onboarding.update!(created_client_at: original_time)

        onboarding.complete_step!(:created_client)
        expect(onboarding.created_client_at).to be_within(1.second).of(original_time)
      end

      it "auto-completes when all steps are done" do
        onboarding.update!(
          created_client_at: 3.days.ago,
          created_project_at: 2.days.ago,
          created_invoice_at: 1.day.ago
        )

        expect { onboarding.complete_step!(:sent_invoice) }
          .to change { onboarding.completed_at }.from(nil)
      end
    end

    describe "#step_completed?" do
      it "returns true for completed steps" do
        onboarding.update!(created_client_at: Time.current)
        expect(onboarding.step_completed?(:created_client)).to be true
      end

      it "returns false for incomplete steps" do
        expect(onboarding.step_completed?(:created_client)).to be false
      end
    end
  end

  describe "progress calculation" do
    describe "#completion_percentage" do
      it "returns 0 for no completed steps" do
        onboarding = build(:onboarding_progress)
        expect(onboarding.completion_percentage).to eq(0)
      end

      it "returns 25 for one completed step" do
        onboarding = build(:onboarding_progress, :with_client)
        expect(onboarding.completion_percentage).to eq(25)
      end

      it "returns 50 for two completed steps" do
        onboarding = build(:onboarding_progress, :with_project)
        expect(onboarding.completion_percentage).to eq(50)
      end

      it "returns 75 for three completed steps" do
        onboarding = build(:onboarding_progress, :with_invoice)
        expect(onboarding.completion_percentage).to eq(75)
      end

      it "returns 100 for all completed steps" do
        onboarding = build(:onboarding_progress, :with_sent_invoice)
        expect(onboarding.completion_percentage).to eq(100)
      end
    end

    describe "#completed_steps_count" do
      it "counts completed steps correctly" do
        onboarding = build(:onboarding_progress, :with_project)
        expect(onboarding.completed_steps_count).to eq(2)
      end
    end

    describe "#total_steps" do
      it "returns 4 total steps" do
        onboarding = build(:onboarding_progress)
        expect(onboarding.total_steps).to eq(4)
      end
    end
  end

  describe "status methods" do
    describe "#dismissed?" do
      it "returns true when dismissed" do
        onboarding = build(:onboarding_progress, :dismissed)
        expect(onboarding.dismissed?).to be true
      end

      it "returns false when not dismissed" do
        onboarding = build(:onboarding_progress)
        expect(onboarding.dismissed?).to be false
      end
    end

    describe "#completed?" do
      it "returns true when completed" do
        onboarding = build(:onboarding_progress, :completed)
        expect(onboarding.completed?).to be true
      end

      it "returns false when not completed" do
        onboarding = build(:onboarding_progress)
        expect(onboarding.completed?).to be false
      end
    end

    describe "#active?" do
      it "returns true when neither dismissed nor completed" do
        onboarding = build(:onboarding_progress)
        expect(onboarding.active?).to be true
      end

      it "returns false when dismissed" do
        onboarding = build(:onboarding_progress, :dismissed)
        expect(onboarding.active?).to be false
      end

      it "returns false when completed" do
        onboarding = build(:onboarding_progress, :completed)
        expect(onboarding.active?).to be false
      end
    end
  end

  describe "#dismiss!" do
    it "sets dismissed_at timestamp" do
      onboarding = create(:onboarding_progress)
      expect { onboarding.dismiss! }
        .to change { onboarding.dismissed_at }.from(nil)
    end
  end

  describe "#next_step" do
    it "returns :created_client when no steps completed" do
      onboarding = build(:onboarding_progress)
      expect(onboarding.next_step).to eq(:created_client)
    end

    it "returns :created_project after client created" do
      onboarding = build(:onboarding_progress, :with_client)
      expect(onboarding.next_step).to eq(:created_project)
    end

    it "returns :created_invoice after project created" do
      onboarding = build(:onboarding_progress, :with_project)
      expect(onboarding.next_step).to eq(:created_invoice)
    end

    it "returns :sent_invoice after invoice created" do
      onboarding = build(:onboarding_progress, :with_invoice)
      expect(onboarding.next_step).to eq(:sent_invoice)
    end

    it "returns nil when all steps completed" do
      onboarding = build(:onboarding_progress, :with_sent_invoice)
      expect(onboarding.next_step).to be_nil
    end
  end

  describe "#steps_summary" do
    it "returns all steps with their completion status" do
      onboarding = build(:onboarding_progress, :with_client)
      summary = onboarding.steps_summary

      expect(summary).to be_an(Array)
      expect(summary.length).to eq(4)

      expect(summary[0][:key]).to eq(:created_client)
      expect(summary[0][:completed]).to be true

      expect(summary[1][:key]).to eq(:created_project)
      expect(summary[1][:completed]).to be false
    end
  end
end
