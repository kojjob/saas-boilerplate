# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:client) }
    it { should have_many(:invoices).dependent(:nullify) }
    it { should have_many(:documents).dependent(:destroy) }
    it { should have_many(:time_entries).dependent(:destroy) }
    it { should have_many(:material_entries).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:project_number).scoped_to(:account_id).allow_nil }
  end

  describe "enums" do
    it "defines status enum" do
      expect(Project.statuses).to eq({
        "draft" => 0,
        "active" => 1,
        "on_hold" => 2,
        "completed" => 3,
        "cancelled" => 4
      })
    end
  end

  describe "callbacks" do
    it "generates project number on create" do
      project = create(:project)
      expect(project.project_number).to match(/^PRJ-\d{5}$/)
    end

    it "increments project number for same account" do
      account = create(:account)
      client = create(:client, account: account)
      project1 = create(:project, account: account, client: client)
      project2 = create(:project, account: account, client: client)

      number1 = project1.project_number.gsub(/\D/, "").to_i
      number2 = project2.project_number.gsub(/\D/, "").to_i

      expect(number2).to eq(number1 + 1)
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:client) { create(:client, account: account) }

    describe ".in_progress" do
      it "returns draft, active, and on_hold projects" do
        draft = create(:project, account: account, client: client, status: :draft)
        active = create(:project, account: account, client: client, status: :active)
        on_hold = create(:project, account: account, client: client, status: :on_hold)
        completed = create(:project, account: account, client: client, status: :completed)
        cancelled = create(:project, account: account, client: client, status: :cancelled)

        in_progress = Project.in_progress

        expect(in_progress).to include(draft, active, on_hold)
        expect(in_progress).not_to include(completed, cancelled)
      end
    end

    describe ".search" do
      it "finds projects by name" do
        project = create(:project, account: account, client: client, name: "Kitchen Renovation")
        expect(Project.search("Kitchen")).to include(project)
      end

      it "finds projects by project_number" do
        project = create(:project, account: account, client: client)
        expect(Project.search(project.project_number)).to include(project)
      end

      it "finds projects by description" do
        project = create(:project, account: account, client: client, description: "Complete bathroom remodel")
        expect(Project.search("bathroom")).to include(project)
      end
    end
  end

  describe "instance methods" do
    describe "#full_address" do
      it "returns formatted address when all fields present" do
        project = build(:project,
          address_line1: "123 Main St",
          city: "New York",
          state: "NY",
          postal_code: "10001"
        )
        expect(project.full_address).to include("123 Main St")
        expect(project.full_address).to include("New York")
      end

      it "returns nil when no address fields present" do
        project = build(:project)
        expect(project.full_address).to be_nil
      end
    end

    describe "#total_time_cost" do
      it "returns sum of billable time entry amounts" do
        project = create(:project)
        user = create(:user)
        # 5 hours * $100/hr = $500
        create(:time_entry, project: project, account: project.account, user: user, billable: true, hours: 5, hourly_rate: 100)
        # 3 hours * $100/hr = $300
        create(:time_entry, project: project, account: project.account, user: user, billable: true, hours: 3, hourly_rate: 100)
        # Non-billable should not count
        create(:time_entry, project: project, account: project.account, user: user, billable: false, hours: 1, hourly_rate: 100)

        expect(project.total_time_cost).to eq(800)
      end
    end

    describe "#total_materials_cost" do
      it "returns sum of billable material entry amounts" do
        project = create(:project)
        user = create(:user)
        # 2 qty * $100/unit = $200 (no markup for simplicity)
        create(:material_entry, project: project, account: project.account, user: user, billable: true, quantity: 2, unit_cost: 100, markup_percentage: 0)
        # 3 qty * $50/unit = $150
        create(:material_entry, project: project, account: project.account, user: user, billable: true, quantity: 3, unit_cost: 50, markup_percentage: 0)
        # Non-billable should not count
        create(:material_entry, project: project, account: project.account, user: user, billable: false, quantity: 1, unit_cost: 50, markup_percentage: 0)

        expect(project.total_materials_cost).to eq(350)
      end
    end

    describe "#total_project_cost" do
      it "returns sum of time and materials costs" do
        project = create(:project)
        user = create(:user)
        create(:time_entry, project: project, account: project.account, user: user, billable: true, hours: 5, hourly_rate: 100)
        create(:material_entry, project: project, account: project.account, user: user, billable: true, quantity: 2, unit_cost: 100, markup_percentage: 0)

        expect(project.total_project_cost).to eq(700)
      end
    end

    describe "#total_hours" do
      it "returns sum of all time entry hours" do
        project = create(:project)
        create(:time_entry, project: project, account: project.account, hours: 8)
        create(:time_entry, project: project, account: project.account, hours: 4)

        expect(project.total_hours).to eq(12)
      end
    end

    describe "#billable_hours" do
      it "returns sum of billable time entry hours only" do
        project = create(:project)
        create(:time_entry, project: project, account: project.account, billable: true, hours: 8)
        create(:time_entry, project: project, account: project.account, billable: false, hours: 4)

        expect(project.billable_hours).to eq(8)
      end
    end

    describe "#budget_remaining" do
      it "returns remaining budget" do
        project = create(:project, budget: 1000)
        user = create(:user)
        # 4 hours * $100/hr = $400
        create(:time_entry, project: project, account: project.account, user: user, billable: true, hours: 4, hourly_rate: 100)

        expect(project.budget_remaining).to eq(600)
      end

      it "returns nil when no budget set" do
        project = create(:project, budget: nil)
        expect(project.budget_remaining).to be_nil
      end
    end

    describe "#budget_percentage_used" do
      it "calculates percentage of budget used" do
        project = create(:project, budget: 1000)
        user = create(:user)
        # 2.5 hours * $100/hr = $250
        create(:time_entry, project: project, account: project.account, user: user, billable: true, hours: 2.5, hourly_rate: 100)

        expect(project.budget_percentage_used).to eq(25.0)
      end

      it "returns 0 when no budget set" do
        project = create(:project, budget: nil)
        expect(project.budget_percentage_used).to eq(0)
      end
    end

    describe "#overdue?" do
      it "returns true for active projects past due date" do
        project = create(:project, :active, due_date: 1.week.ago)
        expect(project.overdue?).to be true
      end

      it "returns false for completed projects past due date" do
        project = create(:project, :completed, due_date: 1.week.ago)
        expect(project.overdue?).to be false
      end

      it "returns false for projects without due date" do
        project = create(:project, :active, due_date: nil)
        expect(project.overdue?).to be false
      end
    end

    describe "#days_until_due" do
      it "returns days until due date" do
        project = create(:project, due_date: 10.days.from_now)
        expect(project.days_until_due).to eq(10)
      end

      it "returns nil when no due date set" do
        project = create(:project, due_date: nil)
        expect(project.days_until_due).to be_nil
      end
    end
  end
end
