# frozen_string_literal: true

require "rails_helper"

RSpec.describe Estimate, type: :model do
  let(:account) { create(:account) }
  let(:client) { create(:client, account: account) }

  describe "associations" do
    subject { create(:estimate, account: account, client: client) }

    it { should belong_to(:account) }
    it { should belong_to(:client) }
    it { should belong_to(:project).optional }
    it { should belong_to(:converted_invoice).class_name("Invoice").optional }
    it { should have_many(:line_items).class_name("EstimateLineItem").dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:estimate, account: account, client: client) }

    # estimate_number is auto-generated, so we test uniqueness rather than presence
    it { should validate_uniqueness_of(:estimate_number).scoped_to(:account_id) }

    context "estimate_number presence" do
      it "generates estimate number automatically if not provided" do
        estimate = build(:estimate, account: account, client: client, estimate_number: nil)
        estimate.valid?
        expect(estimate.estimate_number).to be_present
      end
    end

    context "issue_date presence" do
      it "defaults to current date if not provided" do
        estimate = build(:estimate, account: account, client: client, issue_date: nil)
        estimate.valid?
        expect(estimate.issue_date).to eq(Date.current)
      end
    end

    context "valid_until presence" do
      it "defaults to 30 days from issue date if not provided" do
        estimate = build(:estimate, account: account, client: client, valid_until: nil)
        estimate.valid?
        expect(estimate.valid_until).to eq(Date.current + 30.days)
      end
    end

    context "valid_until validation" do
      it "is invalid if valid_until is before issue_date" do
        estimate = build(:estimate, account: account, client: client, issue_date: Date.current, valid_until: Date.current - 1.day)
        expect(estimate).not_to be_valid
        expect(estimate.errors[:valid_until]).to include("must be after issue date")
      end
    end
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, sent: 1, viewed: 2, accepted: 3, declined: 4, expired: 5, converted: 6) }
  end

  describe "callbacks" do
    describe "before_validation on create" do
      it "sets default dates if not provided" do
        estimate = build(:estimate, account: account, client: client, issue_date: nil, valid_until: nil)
        estimate.valid?
        expect(estimate.issue_date).to eq(Date.current)
        expect(estimate.valid_until).to eq(Date.current + 30.days)
      end

      it "generates estimate number if not provided" do
        estimate = create(:estimate, account: account, client: client, estimate_number: nil)
        expect(estimate.estimate_number).to match(/^EST-\d+$/)
      end

      it "generates sequential estimate numbers" do
        create(:estimate, account: account, client: client, estimate_number: "EST-10001")
        estimate = create(:estimate, account: account, client: client, estimate_number: nil)
        expect(estimate.estimate_number).to eq("EST-10002")
      end
    end

    describe "before_save" do
      it "calculates totals from line items" do
        estimate = create(:estimate, account: account, client: client, tax_rate: 10, discount_amount: 5)
        create(:estimate_line_item, estimate: estimate, quantity: 2, unit_price: 100)
        create(:estimate_line_item, estimate: estimate, quantity: 1, unit_price: 50)

        estimate.reload
        estimate.save

        expect(estimate.subtotal).to eq(250)
        expect(estimate.tax_amount).to eq(25)
        expect(estimate.total_amount).to eq(270)
      end
    end
  end

  describe "scopes" do
    let!(:draft_estimate) { create(:estimate, account: account, client: client, status: :draft) }
    let!(:sent_estimate) { create(:estimate, account: account, client: client, status: :sent) }
    let!(:accepted_estimate) { create(:estimate, account: account, client: client, status: :accepted) }
    let!(:expired_estimate) { create(:estimate, account: account, client: client, status: :expired) }

    describe ".pending" do
      it "returns draft and sent estimates" do
        expect(Estimate.pending).to include(draft_estimate, sent_estimate)
        expect(Estimate.pending).not_to include(accepted_estimate, expired_estimate)
      end
    end

    describe ".active" do
      it "returns estimates that are not expired, declined, or converted" do
        declined_estimate = create(:estimate, account: account, client: client, status: :declined)
        converted_estimate = create(:estimate, account: account, client: client, status: :converted)

        expect(Estimate.active).to include(draft_estimate, sent_estimate, accepted_estimate)
        expect(Estimate.active).not_to include(expired_estimate, declined_estimate, converted_estimate)
      end
    end

    describe ".expiring_soon" do
      it "returns pending estimates expiring within 7 days" do
        expiring_soon = create(:estimate, account: account, client: client, status: :sent, valid_until: 5.days.from_now)
        not_expiring_soon = create(:estimate, account: account, client: client, status: :sent, valid_until: 10.days.from_now)

        expect(Estimate.expiring_soon).to include(expiring_soon)
        expect(Estimate.expiring_soon).not_to include(not_expiring_soon)
      end
    end

    describe ".search" do
      it "finds estimates by estimate number" do
        draft_estimate.update!(estimate_number: "EST-UNIQUE123")
        results = Estimate.search("UNIQUE123")
        expect(results).to include(draft_estimate)
      end

      it "finds estimates by client name" do
        client.update!(name: "John Unique Smith")
        results = Estimate.search("Unique Smith")
        expect(results).to include(draft_estimate)
      end
    end
  end

  describe "instance methods" do
    describe "#mark_as_sent!" do
      let(:estimate) { create(:estimate, account: account, client: client, status: :draft) }

      it "changes status to sent" do
        expect { estimate.mark_as_sent! }.to change { estimate.status }.from("draft").to("sent")
      end

      it "sets sent_at timestamp" do
        estimate.mark_as_sent!
        expect(estimate.sent_at).to be_present
      end
    end

    describe "#mark_as_accepted!" do
      let(:estimate) { create(:estimate, :sent, account: account, client: client) }

      it "changes status to accepted" do
        expect { estimate.mark_as_accepted! }.to change { estimate.status }.from("sent").to("accepted")
      end

      it "sets accepted_at timestamp" do
        estimate.mark_as_accepted!
        expect(estimate.accepted_at).to be_present
      end
    end

    describe "#mark_as_declined!" do
      let(:estimate) { create(:estimate, :sent, account: account, client: client) }

      it "changes status to declined" do
        expect { estimate.mark_as_declined! }.to change { estimate.status }.from("sent").to("declined")
      end

      it "sets declined_at timestamp" do
        estimate.mark_as_declined!
        expect(estimate.declined_at).to be_present
      end
    end

    describe "#expired?" do
      it "returns true if valid_until is in the past" do
        # Set issue_date in the past so valid_until can also be in the past while still being after issue_date
        estimate = create(:estimate, account: account, client: client,
                          issue_date: Date.current - 10.days,
                          valid_until: Date.current - 1.day)
        expect(estimate.expired?).to be true
      end

      it "returns false if valid_until is in the future" do
        estimate = create(:estimate, account: account, client: client, valid_until: Date.current + 1.day)
        expect(estimate.expired?).to be false
      end
    end

    describe "#days_until_expiry" do
      it "returns the number of days until expiry" do
        estimate = create(:estimate, account: account, client: client, valid_until: Date.current + 10.days)
        expect(estimate.days_until_expiry).to eq(10)
      end

      it "returns 0 if already expired" do
        # Set issue_date in the past so valid_until can also be in the past while still being after issue_date
        estimate = create(:estimate, account: account, client: client,
                          issue_date: Date.current - 10.days,
                          valid_until: Date.current - 5.days)
        expect(estimate.days_until_expiry).to eq(0)
      end
    end

    describe "#convert_to_invoice!" do
      let(:estimate) { create(:estimate, :accepted, account: account, client: client, tax_rate: 10, discount_amount: 5) }
      let!(:line_item1) { create(:estimate_line_item, estimate: estimate, description: "Item 1", quantity: 2, unit_price: 100) }
      let!(:line_item2) { create(:estimate_line_item, estimate: estimate, description: "Item 2", quantity: 1, unit_price: 50) }

      it "creates a new invoice" do
        expect { estimate.convert_to_invoice! }.to change { Invoice.count }.by(1)
      end

      it "copies estimate data to invoice" do
        invoice = estimate.convert_to_invoice!

        expect(invoice.account).to eq(estimate.account)
        expect(invoice.client).to eq(estimate.client)
        expect(invoice.project).to eq(estimate.project)
        expect(invoice.tax_rate).to eq(estimate.tax_rate)
        expect(invoice.discount_amount).to eq(estimate.discount_amount)
        expect(invoice.notes).to eq(estimate.notes)
        expect(invoice.terms).to eq(estimate.terms)
      end

      it "copies line items to invoice" do
        invoice = estimate.convert_to_invoice!

        expect(invoice.line_items.count).to eq(2)
        expect(invoice.line_items.map(&:description)).to match_array(["Item 1", "Item 2"])
      end

      it "marks estimate as converted" do
        estimate.convert_to_invoice!
        expect(estimate.reload.status).to eq("converted")
      end

      it "links estimate to invoice" do
        invoice = estimate.convert_to_invoice!
        expect(estimate.reload.converted_invoice).to eq(invoice)
      end

      it "sets converted_at timestamp" do
        estimate.convert_to_invoice!
        expect(estimate.reload.converted_at).to be_present
      end

      it "raises error if estimate is not accepted" do
        draft_estimate = create(:estimate, account: account, client: client, status: :draft)
        expect { draft_estimate.convert_to_invoice! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "raises error if estimate is already converted" do
        estimate.convert_to_invoice!
        expect { estimate.convert_to_invoice! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "#can_convert?" do
      it "returns true for accepted estimates" do
        estimate = create(:estimate, :accepted, account: account, client: client)
        expect(estimate.can_convert?).to be true
      end

      it "returns false for draft estimates" do
        estimate = create(:estimate, account: account, client: client, status: :draft)
        expect(estimate.can_convert?).to be false
      end

      it "returns false for already converted estimates" do
        estimate = create(:estimate, account: account, client: client, status: :converted)
        expect(estimate.can_convert?).to be false
      end
    end

    describe "#status_color" do
      it "returns the correct color for each status" do
        expect(build(:estimate, status: :draft).status_color).to eq("gray")
        expect(build(:estimate, status: :sent).status_color).to eq("blue")
        expect(build(:estimate, status: :viewed).status_color).to eq("indigo")
        expect(build(:estimate, status: :accepted).status_color).to eq("green")
        expect(build(:estimate, status: :declined).status_color).to eq("red")
        expect(build(:estimate, status: :expired).status_color).to eq("amber")
        expect(build(:estimate, status: :converted).status_color).to eq("purple")
      end
    end
  end
end
