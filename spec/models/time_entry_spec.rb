# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeEntry, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:time_entry) }

    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:hours) }
    it { should validate_numericality_of(:hours).is_greater_than(0).is_less_than_or_equal_to(24) }

    it "accepts valid hours" do
      entry = build(:time_entry, hours: 8)
      expect(entry).to be_valid
    end

    it "rejects hours over 24" do
      entry = build(:time_entry, hours: 25)
      expect(entry).not_to be_valid
    end

    it "rejects negative hours" do
      entry = build(:time_entry, hours: -1)
      expect(entry).not_to be_valid
    end
  end

  describe "callbacks" do
    describe "#calculate_total_amount" do
      it "calculates total from hours and hourly_rate when billable" do
        entry = create(:time_entry, :billable, hours: 5, hourly_rate: 100)
        expect(entry.total_amount).to eq(500)
      end

      it "uses effective hourly rate when entry rate is nil" do
        account = create(:account)
        project = create(:project, account: account, hourly_rate: 75)
        entry = create(:time_entry, :billable, account: account, project: project, hours: 4, hourly_rate: nil)
        expect(entry.total_amount).to eq(300)
      end

      it "does not set total_amount for non-billable entries" do
        entry = create(:time_entry, :non_billable, hours: 5, hourly_rate: 100)
        expect(entry.total_amount).to be_nil
      end
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:client) { create(:client, account: account) }
    let(:project) { create(:project, account: account, client: client) }
    let(:user) { create(:user) }

    describe ".billable" do
      it "returns only billable entries" do
        billable = create(:time_entry, :billable, account: account, project: project, user: user)
        non_billable = create(:time_entry, :non_billable, account: account, project: project, user: user)

        expect(TimeEntry.billable).to include(billable)
        expect(TimeEntry.billable).not_to include(non_billable)
      end
    end

    describe ".non_billable" do
      it "returns only non-billable entries" do
        billable = create(:time_entry, :billable, account: account, project: project, user: user)
        non_billable = create(:time_entry, :non_billable, account: account, project: project, user: user)

        expect(TimeEntry.non_billable).to include(non_billable)
        expect(TimeEntry.non_billable).not_to include(billable)
      end
    end

    describe ".invoiced" do
      it "returns only invoiced entries" do
        invoiced = create(:time_entry, account: account, project: project, user: user, invoiced: true)
        not_invoiced = create(:time_entry, account: account, project: project, user: user, invoiced: false)

        expect(TimeEntry.invoiced).to include(invoiced)
        expect(TimeEntry.invoiced).not_to include(not_invoiced)
      end
    end

    describe ".not_invoiced" do
      it "returns only non-invoiced entries" do
        invoiced = create(:time_entry, account: account, project: project, user: user, invoiced: true)
        not_invoiced = create(:time_entry, account: account, project: project, user: user, invoiced: false)

        expect(TimeEntry.not_invoiced).to include(not_invoiced)
        expect(TimeEntry.not_invoiced).not_to include(invoiced)
      end
    end

    describe ".for_date_range" do
      it "returns entries within date range" do
        in_range = create(:time_entry, account: account, project: project, user: user, date: 5.days.ago)
        out_of_range = create(:time_entry, account: account, project: project, user: user, date: 20.days.ago)

        entries = TimeEntry.for_date_range(10.days.ago, Date.current)

        expect(entries).to include(in_range)
        expect(entries).not_to include(out_of_range)
      end
    end

    describe ".recent" do
      it "orders by date descending" do
        old = create(:time_entry, account: account, project: project, user: user, date: 5.days.ago)
        recent = create(:time_entry, account: account, project: project, user: user, date: 1.day.ago)

        expect(TimeEntry.recent.first).to eq(recent)
        expect(TimeEntry.recent.last).to eq(old)
      end
    end

    describe ".this_week" do
      it "returns entries from current week" do
        this_week = create(:time_entry, account: account, project: project, user: user, date: Date.current)
        last_week = create(:time_entry, account: account, project: project, user: user, date: 10.days.ago)

        expect(TimeEntry.this_week).to include(this_week)
        expect(TimeEntry.this_week).not_to include(last_week)
      end
    end

    describe ".this_month" do
      it "returns entries from current month" do
        this_month = create(:time_entry, account: account, project: project, user: user, date: Date.current)
        last_month = create(:time_entry, account: account, project: project, user: user, date: 2.months.ago)

        expect(TimeEntry.this_month).to include(this_month)
        expect(TimeEntry.this_month).not_to include(last_month)
      end
    end
  end

  describe "instance methods" do
    describe "#effective_hourly_rate" do
      it "returns entry hourly_rate when set" do
        entry = build(:time_entry, hourly_rate: 120)
        expect(entry.effective_hourly_rate).to eq(120)
      end

      it "falls back to project hourly_rate when entry rate is nil" do
        project = create(:project, hourly_rate: 90)
        entry = build(:time_entry, project: project, hourly_rate: nil)
        expect(entry.effective_hourly_rate).to eq(90)
      end

      it "returns 0 when no rate is set anywhere" do
        project = create(:project, hourly_rate: nil)
        entry = build(:time_entry, project: project, hourly_rate: nil)
        expect(entry.effective_hourly_rate).to eq(0)
      end
    end

    describe "#mark_as_invoiced!" do
      it "sets invoiced to true" do
        entry = create(:time_entry, invoiced: false)
        entry.mark_as_invoiced!
        expect(entry.reload.invoiced).to be true
      end
    end
  end
end
