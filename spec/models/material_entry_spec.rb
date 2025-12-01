# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaterialEntry, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:material_entry) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_presence_of(:unit_cost) }
    it { should validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0) }

    it "accepts valid quantity" do
      entry = build(:material_entry, quantity: 5)
      expect(entry).to be_valid
    end

    it "rejects zero quantity" do
      entry = build(:material_entry, quantity: 0)
      expect(entry).not_to be_valid
    end

    it "rejects negative quantity" do
      entry = build(:material_entry, quantity: -1)
      expect(entry).not_to be_valid
    end

    it "accepts zero unit_cost" do
      entry = build(:material_entry, unit_cost: 0)
      expect(entry).to be_valid
    end

    it "rejects negative unit_cost" do
      entry = build(:material_entry, unit_cost: -10)
      expect(entry).not_to be_valid
    end
  end

  describe "callbacks" do
    describe "#calculate_total_amount" do
      it "calculates total from subtotal and markup when billable" do
        entry = create(:material_entry, quantity: 10, unit_cost: 50, markup_percentage: 20, billable: true)
        # subtotal = 10 * 50 = 500, markup = 500 * 0.20 = 100, total = 600
        expect(entry.total_amount).to eq(600)
      end

      it "calculates total with zero markup when no markup set" do
        entry = create(:material_entry, :no_markup, quantity: 5, unit_cost: 100, billable: true)
        # subtotal = 5 * 100 = 500, markup = 0, total = 500
        expect(entry.total_amount).to eq(500)
      end

      it "does not set total_amount for non-billable entries" do
        entry = create(:material_entry, :non_billable, quantity: 5, unit_cost: 100)
        expect(entry.total_amount).to eq(0)
      end

      it "handles high markup percentages" do
        entry = create(:material_entry, :high_markup, quantity: 2, unit_cost: 100, billable: true)
        # subtotal = 200, markup = 200 * 0.50 = 100, total = 300
        expect(entry.total_amount).to eq(300)
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
        billable = create(:material_entry, account: account, project: project, user: user, billable: true)
        non_billable = create(:material_entry, :non_billable, account: account, project: project, user: user)

        expect(MaterialEntry.billable).to include(billable)
        expect(MaterialEntry.billable).not_to include(non_billable)
      end
    end

    describe ".non_billable" do
      it "returns only non-billable entries" do
        billable = create(:material_entry, account: account, project: project, user: user, billable: true)
        non_billable = create(:material_entry, :non_billable, account: account, project: project, user: user)

        expect(MaterialEntry.non_billable).to include(non_billable)
        expect(MaterialEntry.non_billable).not_to include(billable)
      end
    end

    describe ".invoiced" do
      it "returns only invoiced entries" do
        invoiced = create(:material_entry, account: account, project: project, user: user, invoiced: true)
        not_invoiced = create(:material_entry, account: account, project: project, user: user, invoiced: false)

        expect(MaterialEntry.invoiced).to include(invoiced)
        expect(MaterialEntry.invoiced).not_to include(not_invoiced)
      end
    end

    describe ".not_invoiced" do
      it "returns only non-invoiced entries" do
        invoiced = create(:material_entry, account: account, project: project, user: user, invoiced: true)
        not_invoiced = create(:material_entry, account: account, project: project, user: user, invoiced: false)

        expect(MaterialEntry.not_invoiced).to include(not_invoiced)
        expect(MaterialEntry.not_invoiced).not_to include(invoiced)
      end
    end

    describe ".for_date_range" do
      it "returns entries within date range" do
        in_range = create(:material_entry, account: account, project: project, user: user, date: 5.days.ago)
        out_of_range = create(:material_entry, account: account, project: project, user: user, date: 20.days.ago)

        entries = MaterialEntry.for_date_range(10.days.ago, Date.current)

        expect(entries).to include(in_range)
        expect(entries).not_to include(out_of_range)
      end
    end

    describe ".recent" do
      it "orders by date descending" do
        old = create(:material_entry, account: account, project: project, user: user, date: 5.days.ago)
        recent = create(:material_entry, account: account, project: project, user: user, date: 1.day.ago)

        expect(MaterialEntry.recent.first).to eq(recent)
        expect(MaterialEntry.recent.last).to eq(old)
      end
    end

    describe ".this_week" do
      it "returns entries from current week" do
        this_week = create(:material_entry, account: account, project: project, user: user, date: Date.current)
        last_week = create(:material_entry, account: account, project: project, user: user, date: 10.days.ago)

        expect(MaterialEntry.this_week).to include(this_week)
        expect(MaterialEntry.this_week).not_to include(last_week)
      end
    end

    describe ".this_month" do
      it "returns entries from current month" do
        this_month = create(:material_entry, account: account, project: project, user: user, date: Date.current)
        last_month = create(:material_entry, account: account, project: project, user: user, date: 2.months.ago)

        expect(MaterialEntry.this_month).to include(this_month)
        expect(MaterialEntry.this_month).not_to include(last_month)
      end
    end
  end

  describe "instance methods" do
    describe "#subtotal" do
      it "calculates quantity times unit_cost" do
        entry = build(:material_entry, quantity: 8, unit_cost: 25)
        expect(entry.subtotal).to eq(200)
      end

      it "handles nil quantity" do
        entry = build(:material_entry, quantity: nil, unit_cost: 50)
        entry.valid? # Trigger validation to set defaults
        expect(entry.subtotal).to eq(0)
      end

      it "handles nil unit_cost" do
        entry = build(:material_entry, quantity: 10, unit_cost: nil)
        entry.valid?
        expect(entry.subtotal).to eq(0)
      end
    end

    describe "#markup_amount" do
      it "calculates markup based on subtotal and percentage" do
        entry = build(:material_entry, quantity: 10, unit_cost: 100, markup_percentage: 25)
        # subtotal = 1000, markup = 1000 * 0.25 = 250
        expect(entry.markup_amount).to eq(250)
      end

      it "returns 0 when markup_percentage is nil" do
        entry = build(:material_entry, quantity: 10, unit_cost: 100, markup_percentage: nil)
        expect(entry.markup_amount).to eq(0)
      end

      it "returns 0 when markup_percentage is 0" do
        entry = build(:material_entry, :no_markup, quantity: 10, unit_cost: 100)
        expect(entry.markup_amount).to eq(0)
      end
    end

    describe "#mark_as_invoiced!" do
      it "sets invoiced to true" do
        entry = create(:material_entry, invoiced: false)
        entry.mark_as_invoiced!
        expect(entry.reload.invoiced).to be true
      end
    end
  end
end
