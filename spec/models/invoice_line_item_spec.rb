# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceLineItem, type: :model do
  describe "associations" do
    it "belongs to invoice" do
      association = described_class.reflect_on_association(:invoice)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe "validations" do
    describe "description" do
      it "is required" do
        line_item = build(:invoice_line_item, description: nil)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:description]).to include("can't be blank")
      end

      it "is valid with a description" do
        line_item = build(:invoice_line_item, description: "Service labor")
        expect(line_item).to be_valid
      end
    end

    describe "unit_price" do
      it "is required" do
        invoice = create(:invoice)
        line_item = InvoiceLineItem.new(invoice: invoice, description: "Test", quantity: 1, unit_price: nil)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:unit_price]).to include("can't be blank")
      end

      it "must be greater than or equal to zero" do
        line_item = build(:invoice_line_item, unit_price: -1)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:unit_price]).to include("must be greater than or equal to 0")
      end

      it "allows zero" do
        line_item = build(:invoice_line_item, unit_price: 0)
        expect(line_item).to be_valid
      end

      it "allows positive values" do
        line_item = build(:invoice_line_item, unit_price: 100.50)
        expect(line_item).to be_valid
      end
    end

    describe "quantity" do
      it "is required" do
        invoice = create(:invoice)
        line_item = InvoiceLineItem.new(invoice: invoice, description: "Test", unit_price: 100, quantity: nil)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:quantity]).to include("can't be blank")
      end

      it "must be greater than zero" do
        line_item = build(:invoice_line_item, quantity: 0)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:quantity]).to include("must be greater than 0")
      end

      it "does not allow negative values" do
        line_item = build(:invoice_line_item, quantity: -1)
        expect(line_item).not_to be_valid
        expect(line_item.errors[:quantity]).to include("must be greater than 0")
      end

      it "allows positive values" do
        line_item = build(:invoice_line_item, quantity: 5)
        expect(line_item).to be_valid
      end

      it "allows decimal quantities" do
        line_item = build(:invoice_line_item, quantity: 2.5)
        expect(line_item).to be_valid
      end
    end
  end

  describe "callbacks" do
    describe "before_save" do
      describe "#calculate_amount" do
        it "calculates amount from quantity and unit_price" do
          line_item = create(:invoice_line_item, quantity: 3, unit_price: 100.00)
          expect(line_item.amount).to eq(300.00)
        end

        it "handles decimal quantities" do
          line_item = create(:invoice_line_item, quantity: 2.5, unit_price: 40.00)
          expect(line_item.amount).to eq(100.00)
        end

        it "handles decimal unit prices" do
          line_item = create(:invoice_line_item, quantity: 2, unit_price: 49.99)
          expect(line_item.amount).to eq(99.98)
        end

        it "handles both decimal values" do
          line_item = create(:invoice_line_item, quantity: 1.5, unit_price: 33.33)
          expect(line_item.amount).to be_within(0.01).of(49.995)
        end

        it "recalculates on update" do
          line_item = create(:invoice_line_item, quantity: 2, unit_price: 50.00)
          expect(line_item.amount).to eq(100.00)

          line_item.update!(quantity: 4)
          expect(line_item.amount).to eq(200.00)
        end

        it "handles nil quantity by treating it as zero" do
          line_item = build(:invoice_line_item, unit_price: 100.00)
          line_item.quantity = nil
          # The callback runs before validation, so we can test the calculation logic
          line_item.send(:calculate_amount)
          expect(line_item.amount).to eq(0)
        end

        it "handles nil unit_price by treating it as zero" do
          line_item = build(:invoice_line_item, quantity: 5)
          line_item.unit_price = nil
          line_item.send(:calculate_amount)
          expect(line_item.amount).to eq(0)
        end
      end
    end
  end

  describe "default scope" do
    it "orders by position and created_at" do
      invoice = create(:invoice)

      create(:invoice_line_item, invoice: invoice, position: 2, description: "Third")
      create(:invoice_line_item, invoice: invoice, position: 0, description: "First")
      create(:invoice_line_item, invoice: invoice, position: 1, description: "Second")

      # Reload to get fresh association with default scope applied
      expect(invoice.reload.line_items.pluck(:description)).to eq(["First", "Second", "Third"])
    end

    it "orders by created_at when positions are equal" do
      invoice = create(:invoice)

      create(:invoice_line_item, invoice: invoice, position: 0, description: "First")
      sleep(0.01) # Ensure different created_at
      create(:invoice_line_item, invoice: invoice, position: 0, description: "Second")

      expect(invoice.reload.line_items.pluck(:description)).to eq(["First", "Second"])
    end
  end

  describe "factory" do
    it "creates a valid invoice line item" do
      line_item = build(:invoice_line_item)
      expect(line_item).to be_valid
    end

    it "associates with an invoice" do
      line_item = create(:invoice_line_item)
      expect(line_item.invoice).to be_present
    end
  end

  describe "integration with invoice" do
    it "updates invoice totals when created" do
      invoice = create(:invoice, subtotal: 0, total_amount: 0)

      create(:invoice_line_item, invoice: invoice, quantity: 2, unit_price: 100.00)
      invoice.reload
      invoice.update!(tax_rate: 0) # Trigger recalculation

      expect(invoice.subtotal).to eq(200.00)
    end

    it "has dependent destroy association configured on invoice" do
      association = Invoice.reflect_on_association(:line_items)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end
end
