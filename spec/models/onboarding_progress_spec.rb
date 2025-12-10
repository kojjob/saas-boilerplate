# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnboardingProgress, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:onboarding_progress) }

    it { is_expected.to validate_uniqueness_of(:user_id) }
  end

  describe "factory" do
    it "creates a valid onboarding progress" do
      onboarding = build(:onboarding_progress)
      expect(onboarding).to be_valid
    end
  end

  describe "default values" do
    let(:onboarding) { create(:onboarding_progress) }

    it "starts with all steps incomplete" do
      expect(onboarding.client_created).to be false
      expect(onboarding.project_created).to be false
      expect(onboarding.invoice_created).to be false
      expect(onboarding.invoice_sent).to be false
      expect(onboarding.dismissed).to be false
    end
  end

  describe "#complete_step!" do
    let(:onboarding) { create(:onboarding_progress) }

    it "marks client_created step as complete with timestamp" do
      freeze_time do
        onboarding.complete_step!(:client_created)
        expect(onboarding.client_created).to be true
        expect(onboarding.client_created_at).to eq(Time.current)
      end
    end

    it "marks project_created step as complete with timestamp" do
      freeze_time do
        onboarding.complete_step!(:project_created)
        expect(onboarding.project_created).to be true
        expect(onboarding.project_created_at).to eq(Time.current)
      end
    end

    it "marks invoice_created step as complete with timestamp" do
      freeze_time do
        onboarding.complete_step!(:invoice_created)
        expect(onboarding.invoice_created).to be true
        expect(onboarding.invoice_created_at).to eq(Time.current)
      end
    end

    it "marks invoice_sent step as complete with timestamp" do
      freeze_time do
        onboarding.complete_step!(:invoice_sent)
        expect(onboarding.invoice_sent).to be true
        expect(onboarding.invoice_sent_at).to eq(Time.current)
      end
    end

    it "does not update timestamp if step already complete" do
      original_time = 1.day.ago
      onboarding.update!(client_created: true, client_created_at: original_time)

      onboarding.complete_step!(:client_created)
      expect(onboarding.client_created_at).to eq(original_time)
    end

    it "raises error for invalid step" do
      expect { onboarding.complete_step!(:invalid_step) }.to raise_error(ArgumentError)
    end
  end

  describe "#completed_steps_count" do
    let(:onboarding) { create(:onboarding_progress) }

    it "returns 0 when no steps completed" do
      expect(onboarding.completed_steps_count).to eq(0)
    end

    it "returns correct count when some steps completed" do
      onboarding.update!(client_created: true, project_created: true)
      expect(onboarding.completed_steps_count).to eq(2)
    end

    it "returns 4 when all steps completed" do
      onboarding.update!(
        client_created: true,
        project_created: true,
        invoice_created: true,
        invoice_sent: true
      )
      expect(onboarding.completed_steps_count).to eq(4)
    end
  end

  describe "#total_steps" do
    it "returns 4" do
      onboarding = build(:onboarding_progress)
      expect(onboarding.total_steps).to eq(4)
    end
  end

  describe "#progress_percentage" do
    let(:onboarding) { create(:onboarding_progress) }

    it "returns 0 when no steps completed" do
      expect(onboarding.progress_percentage).to eq(0)
    end

    it "returns 25 when one step completed" do
      onboarding.update!(client_created: true)
      expect(onboarding.progress_percentage).to eq(25)
    end

    it "returns 50 when two steps completed" do
      onboarding.update!(client_created: true, project_created: true)
      expect(onboarding.progress_percentage).to eq(50)
    end

    it "returns 100 when all steps completed" do
      onboarding.update!(
        client_created: true,
        project_created: true,
        invoice_created: true,
        invoice_sent: true
      )
      expect(onboarding.progress_percentage).to eq(100)
    end
  end

  describe "#completed?" do
    let(:onboarding) { create(:onboarding_progress) }

    it "returns false when not all steps completed" do
      onboarding.update!(client_created: true, project_created: true)
      expect(onboarding.completed?).to be false
    end

    it "returns true when all steps completed" do
      onboarding.update!(
        client_created: true,
        project_created: true,
        invoice_created: true,
        invoice_sent: true
      )
      expect(onboarding.completed?).to be true
    end
  end

  describe "#visible?" do
    let(:onboarding) { create(:onboarding_progress) }

    it "returns true when not dismissed and not completed" do
      expect(onboarding.visible?).to be true
    end

    it "returns false when dismissed" do
      onboarding.update!(dismissed: true)
      expect(onboarding.visible?).to be false
    end

    it "returns false when all steps completed" do
      onboarding.update!(
        client_created: true,
        project_created: true,
        invoice_created: true,
        invoice_sent: true
      )
      expect(onboarding.visible?).to be false
    end
  end

  describe "#dismiss!" do
    let(:onboarding) { create(:onboarding_progress) }

    it "sets dismissed to true" do
      onboarding.dismiss!
      expect(onboarding.dismissed).to be true
    end

    it "sets dismissed_at timestamp" do
      freeze_time do
        onboarding.dismiss!
        expect(onboarding.dismissed_at).to eq(Time.current)
      end
    end
  end

  describe "#next_step" do
    let(:onboarding) { create(:onboarding_progress) }

    it "returns :client_created when no steps completed" do
      expect(onboarding.next_step).to eq(:client_created)
    end

    it "returns :project_created when client created" do
      onboarding.update!(client_created: true)
      expect(onboarding.next_step).to eq(:project_created)
    end

    it "returns :invoice_created when project created" do
      onboarding.update!(client_created: true, project_created: true)
      expect(onboarding.next_step).to eq(:invoice_created)
    end

    it "returns :invoice_sent when invoice created" do
      onboarding.update!(client_created: true, project_created: true, invoice_created: true)
      expect(onboarding.next_step).to eq(:invoice_sent)
    end

    it "returns nil when all steps completed" do
      onboarding.update!(
        client_created: true,
        project_created: true,
        invoice_created: true,
        invoice_sent: true
      )
      expect(onboarding.next_step).to be_nil
    end
  end

  describe ".find_or_create_for" do
    let(:user) { create(:user) }

    it "creates onboarding progress for new user" do
      expect { OnboardingProgress.find_or_create_for(user) }.to change(OnboardingProgress, :count).by(1)
    end

    it "returns existing onboarding progress for user" do
      existing = create(:onboarding_progress, user: user)
      result = OnboardingProgress.find_or_create_for(user)
      expect(result).to eq(existing)
    end

    it "does not create duplicate for existing user" do
      create(:onboarding_progress, user: user)
      expect { OnboardingProgress.find_or_create_for(user) }.not_to change(OnboardingProgress, :count)
    end
  end
end
