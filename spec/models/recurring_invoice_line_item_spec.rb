# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringInvoiceLineItem, type: :model do
  describe "associations" do
    it { should belong_to(:recurring_invoice) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe "callbacks" do
    describe "#calculate_amount" do
      it "calculates amount from quantity and unit_price" do
        line_item = build(:recurring_invoice_line_item, quantity: 3, unit_price: 100.00)
        line_item.valid?
        expect(line_item.amount).to eq(300.00)
      end

      it "handles decimal quantities" do
        line_item = build(:recurring_invoice_line_item, quantity: 2.5, unit_price: 40.00)
        line_item.valid?
        expect(line_item.amount).to eq(100.00)
      end

      it "rounds to two decimal places" do
        line_item = build(:recurring_invoice_line_item, quantity: 3, unit_price: 33.33)
        line_item.valid?
        expect(line_item.amount).to eq(99.99)
      end
    end
  end

  describe "default_scope" do
    it "orders by position ascending" do
      recurring_invoice = create(:recurring_invoice)
      item3 = create(:recurring_invoice_line_item, recurring_invoice: recurring_invoice, position: 3)
      item1 = create(:recurring_invoice_line_item, recurring_invoice: recurring_invoice, position: 1)
      item2 = create(:recurring_invoice_line_item, recurring_invoice: recurring_invoice, position: 2)

      expect(recurring_invoice.line_items.pluck(:id)).to eq([item1.id, item2.id, item3.id])
    end
  end
end
