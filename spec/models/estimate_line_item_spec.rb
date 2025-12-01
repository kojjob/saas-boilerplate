# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimateLineItem, type: :model do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }
  let(:estimate) { create(:estimate, account: account, client: client) }

  describe "associations" do
    it { should belong_to(:estimate) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than(0) }
  end

  describe "callbacks" do
    describe "before_save" do
      it "calculates amount from quantity and unit_price" do
        line_item = create(:estimate_line_item, estimate: estimate, quantity: 3, unit_price: 100)
        expect(line_item.amount).to eq(300)
      end
    end
  end

  describe "default_scope" do
    it "orders by position and created_at" do
      item3 = create(:estimate_line_item, estimate: estimate, position: 3, description: "Third")
      item1 = create(:estimate_line_item, estimate: estimate, position: 1, description: "First")
      item2 = create(:estimate_line_item, estimate: estimate, position: 2, description: "Second")

      expect(estimate.line_items.pluck(:description)).to eq(["First", "Second", "Third"])
    end
  end
end
