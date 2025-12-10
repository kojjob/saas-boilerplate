# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expense, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:client) { create(:client, account: account) }
  let(:project) { create(:project, account: account, client: client) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to belong_to(:client).optional }
    it { is_expected.to have_one_attached(:receipt) }
  end

  describe "validations" do
    subject { build(:expense, account: account) }

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:expense_date) }
    it { is_expected.to validate_presence_of(:category) }

    it "validates currency is supported" do
      expense = build(:expense, account: account, currency: "INVALID")
      expect(expense).not_to be_valid
      expect(expense.errors[:currency]).to include("is not a supported currency")
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:category).with_values(
        software: 0,
        hardware: 1,
        travel: 2,
        meals: 3,
        office: 4,
        professional_services: 5,
        marketing: 6,
        utilities: 7,
        subscriptions: 8,
        other: 9
      )
    }
  end

  describe "scopes" do
    let!(:expense1) { create(:expense, account: account, expense_date: 1.day.ago, category: :software) }
    let!(:expense2) { create(:expense, account: account, expense_date: 1.week.ago, category: :travel) }
    let!(:expense3) { create(:expense, account: account, expense_date: 2.months.ago, billable: true) }
    let!(:expense4) { create(:expense, account: account, expense_date: 1.month.ago, reimbursable: true) }

    describe ".recent" do
      it "returns expenses ordered by expense_date desc" do
        expect(Expense.recent.first).to eq(expense1)
      end
    end

    describe ".by_category" do
      it "returns expenses filtered by category" do
        expect(Expense.by_category(:software)).to include(expense1)
        expect(Expense.by_category(:software)).not_to include(expense2)
      end
    end

    describe ".this_month" do
      it "returns expenses from current month" do
        this_month_expense = create(:expense, account: account, expense_date: Date.current)
        expect(Expense.this_month).to include(this_month_expense)
        expect(Expense.this_month).not_to include(expense3)
      end
    end

    describe ".this_year" do
      it "returns expenses from current year" do
        expect(Expense.this_year).to include(expense1, expense2)
      end
    end

    describe ".billable" do
      it "returns only billable expenses" do
        expect(Expense.billable).to include(expense3)
        expect(Expense.billable).not_to include(expense1)
      end
    end

    describe ".reimbursable" do
      it "returns only reimbursable expenses" do
        expect(Expense.reimbursable).to include(expense4)
        expect(Expense.reimbursable).not_to include(expense1)
      end
    end

    describe ".search" do
      it "searches by description" do
        expense = create(:expense, account: account, description: "Adobe subscription")
        expect(Expense.search("Adobe")).to include(expense)
      end

      it "searches by vendor" do
        expense = create(:expense, account: account, vendor: "Apple Inc")
        expect(Expense.search("Apple")).to include(expense)
      end
    end
  end

  describe "callbacks" do
    describe "set_default_currency" do
      context "when currency is not set" do
        it "uses account default currency" do
          account.update!(default_currency: "EUR")
          expense = create(:expense, account: account, currency: nil)
          expect(expense.currency).to eq("EUR")
        end

        it "defaults to USD when account has no default" do
          expense = create(:expense, account: account, currency: nil)
          expect(expense.currency).to eq("USD")
        end
      end

      context "when currency is set" do
        it "keeps the specified currency" do
          expense = create(:expense, account: account, currency: "GBP")
          expect(expense.currency).to eq("GBP")
        end
      end
    end
  end

  describe "instance methods" do
    let(:expense) { create(:expense, account: account, amount: 150.00, currency: "USD") }

    describe "#formatted_amount" do
      it "returns amount with currency symbol" do
        expect(expense.formatted_amount).to eq("$150.00")
      end

      it "handles different currencies" do
        euro_expense = create(:expense, account: account, amount: 100.00, currency: "EUR")
        expect(euro_expense.formatted_amount).to eq("€100.00")
      end
    end

    describe "#receipt_attached?" do
      it "returns false when no receipt is attached" do
        expect(expense.receipt_attached?).to be false
      end

      it "returns true when receipt is attached" do
        expense.receipt.attach(
          io: StringIO.new("fake receipt content"),
          filename: "receipt.pdf",
          content_type: "application/pdf"
        )
        expect(expense.receipt_attached?).to be true
      end
    end

    describe "#category_display_name" do
      it "returns humanized category name" do
        expense = create(:expense, account: account, category: :professional_services)
        expect(expense.category_display_name).to eq("Professional services")
      end
    end
  end

  describe "class methods" do
    describe ".total_amount" do
      it "returns sum of all expense amounts" do
        create(:expense, account: account, amount: 100.00)
        create(:expense, account: account, amount: 50.00)
        create(:expense, account: account, amount: 25.50)

        expect(account.expenses.total_amount).to eq(175.50)
      end
    end

    describe ".by_category_summary" do
      it "returns expenses grouped by category with totals" do
        create(:expense, account: account, category: :software, amount: 100)
        create(:expense, account: account, category: :software, amount: 50)
        create(:expense, account: account, category: :travel, amount: 200)

        summary = account.expenses.by_category_summary
        expect(summary[:software]).to eq(150)
        expect(summary[:travel]).to eq(200)
      end
    end
  end

  describe "associations with project and client" do
    it "can be associated with a project" do
      expense = create(:expense, account: account, project: project)
      expect(expense.project).to eq(project)
    end

    it "can be associated with a client" do
      expense = create(:expense, account: account, client: client)
      expect(expense.client).to eq(client)
    end

    it "inherits client from project when project is set" do
      expense = create(:expense, account: account, project: project)
      expect(expense.effective_client).to eq(project.client)
    end
  end

  describe "Currencyable integration" do
    let(:expense) { create(:expense, account: account, currency: "GBP") }

    it "includes Currencyable concern" do
      expect(Expense.ancestors).to include(Currencyable)
    end

    it "provides currency_symbol" do
      expect(expense.currency_symbol).to eq("£")
    end

    it "provides currency_name" do
      expect(expense.currency_name).to eq("British Pound")
    end
  end
end
