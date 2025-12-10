# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringInvoice, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:client) }
    it { should belong_to(:project).optional }
    it { should have_many(:invoices).dependent(:nullify) }
    it { should have_many(:line_items).class_name("RecurringInvoiceLineItem").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:frequency) }
    it { should validate_presence_of(:start_date) }

    context "payment_terms validation" do
      subject { build(:recurring_invoice, payment_terms: -1) }

      it "validates payment_terms is non-negative" do
        expect(subject).not_to be_valid
        expect(subject.errors[:payment_terms]).to include("must be greater than or equal to 0")
      end
    end

    context "occurrences_limit validation" do
      subject { build(:recurring_invoice, occurrences_limit: 0) }

      it "validates occurrences_limit is positive when present" do
        expect(subject).not_to be_valid
        expect(subject.errors[:occurrences_limit]).to include("must be greater than 0")
      end
    end
  end

  describe "enums" do
    it {
      should define_enum_for(:frequency).with_values(
        weekly: 0,
        biweekly: 1,
        monthly: 2,
        quarterly: 3,
        annually: 4
      )
    }

    it {
      should define_enum_for(:status).with_values(
        active: 0,
        paused: 1,
        cancelled: 2,
        completed: 3
      )
    }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_recurring) { create(:recurring_invoice, status: :active) }
      let!(:paused_recurring) { create(:recurring_invoice, status: :paused) }

      it "returns only active recurring invoices" do
        expect(described_class.active).to include(active_recurring)
        expect(described_class.active).not_to include(paused_recurring)
      end
    end

    describe ".due_for_generation" do
      let!(:due_today) { create(:recurring_invoice, :active, next_occurrence_date: Date.current) }
      let!(:due_yesterday) { create(:recurring_invoice, :active, next_occurrence_date: Date.current - 1.day) }
      let!(:due_tomorrow) { create(:recurring_invoice, :active, next_occurrence_date: Date.current + 1.day) }
      let!(:paused_due) { create(:recurring_invoice, :paused, next_occurrence_date: Date.current) }

      it "returns active recurring invoices due today or earlier" do
        result = described_class.due_for_generation
        expect(result).to include(due_today, due_yesterday)
        expect(result).not_to include(due_tomorrow, paused_due)
      end
    end
  end

  describe "callbacks" do
    describe "#set_next_occurrence_date" do
      context "on create" do
        it "sets next_occurrence_date to start_date" do
          recurring = create(:recurring_invoice, start_date: Date.current + 7.days)
          expect(recurring.next_occurrence_date).to eq(Date.current + 7.days)
        end
      end
    end
  end

  describe "instance methods" do
    describe "#advance_next_occurrence!" do
      it "advances weekly by 1 week" do
        recurring = create(:recurring_invoice, :weekly, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.next_occurrence_date).to eq(Date.current + 1.week)
      end

      it "advances biweekly by 2 weeks" do
        recurring = create(:recurring_invoice, :biweekly, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.next_occurrence_date).to eq(Date.current + 2.weeks)
      end

      it "advances monthly by 1 month" do
        recurring = create(:recurring_invoice, :monthly, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.next_occurrence_date).to eq(Date.current + 1.month)
      end

      it "advances quarterly by 3 months" do
        recurring = create(:recurring_invoice, :quarterly, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.next_occurrence_date).to eq(Date.current + 3.months)
      end

      it "advances annually by 1 year" do
        recurring = create(:recurring_invoice, :annually, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.next_occurrence_date).to eq(Date.current + 1.year)
      end

      it "increments occurrences_count" do
        recurring = create(:recurring_invoice, occurrences_count: 0)
        expect { recurring.advance_next_occurrence! }.to change { recurring.occurrences_count }.from(0).to(1)
      end

      it "marks as completed when occurrences_limit is reached" do
        recurring = create(:recurring_invoice, :active, occurrences_limit: 1, occurrences_count: 0)
        recurring.advance_next_occurrence!
        expect(recurring.status).to eq("completed")
      end

      it "marks as completed when end_date is reached" do
        recurring = create(:recurring_invoice, :active, :weekly, end_date: Date.current + 3.days, next_occurrence_date: Date.current)
        recurring.advance_next_occurrence!
        expect(recurring.status).to eq("completed")
      end
    end

    describe "#can_generate?" do
      it "returns true when active and due" do
        recurring = create(:recurring_invoice, :active, next_occurrence_date: Date.current)
        expect(recurring.can_generate?).to be true
      end

      it "returns false when paused" do
        recurring = create(:recurring_invoice, :paused, next_occurrence_date: Date.current)
        expect(recurring.can_generate?).to be false
      end

      it "returns false when next_occurrence_date is in the future" do
        recurring = create(:recurring_invoice, :active, next_occurrence_date: Date.current + 1.day)
        expect(recurring.can_generate?).to be false
      end

      it "returns false when end_date has passed" do
        recurring = create(:recurring_invoice, :active, end_date: Date.current - 1.day)
        expect(recurring.can_generate?).to be false
      end

      it "returns false when occurrences_limit reached" do
        recurring = create(:recurring_invoice, :active, occurrences_limit: 5, occurrences_count: 5)
        expect(recurring.can_generate?).to be false
      end
    end

    describe "#pause!" do
      it "changes status to paused" do
        recurring = create(:recurring_invoice, :active)
        expect { recurring.pause! }.to change { recurring.status }.from("active").to("paused")
      end
    end

    describe "#resume!" do
      it "changes status to active" do
        recurring = create(:recurring_invoice, :paused)
        expect { recurring.resume! }.to change { recurring.status }.from("paused").to("active")
      end
    end

    describe "#cancel!" do
      it "changes status to cancelled" do
        recurring = create(:recurring_invoice, :active)
        expect { recurring.cancel! }.to change { recurring.status }.from("active").to("cancelled")
      end
    end

    describe "#frequency_display_name" do
      it "returns humanized frequency" do
        recurring = build(:recurring_invoice, :monthly)
        expect(recurring.frequency_display_name).to eq("Monthly")
      end
    end

    describe "#remaining_occurrences" do
      context "when occurrences_limit is set" do
        it "returns the difference between limit and count" do
          recurring = build(:recurring_invoice, occurrences_limit: 10, occurrences_count: 3)
          expect(recurring.remaining_occurrences).to eq(7)
        end
      end

      context "when occurrences_limit is nil" do
        it "returns nil (unlimited)" do
          recurring = build(:recurring_invoice, occurrences_limit: nil)
          expect(recurring.remaining_occurrences).to be_nil
        end
      end
    end
  end

  describe "Currencyable integration" do
    it "includes Currencyable concern" do
      expect(described_class.ancestors).to include(Currencyable)
    end

    it "provides currency_symbol" do
      recurring = build(:recurring_invoice, currency: "USD")
      expect(recurring.currency_symbol).to eq("$")
    end

    it "provides currency_name" do
      recurring = build(:recurring_invoice, currency: "EUR")
      expect(recurring.currency_name).to eq("Euro")
    end
  end
end
