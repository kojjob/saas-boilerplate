# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Estimates", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, account: account, role: :owner) }
  let(:client) { create(:client, account: account) }

  before do
    sign_in user
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
  end

  describe "GET /estimates" do
    let!(:draft_estimate) { create(:estimate, account: account, client: client, status: :draft) }
    let!(:sent_estimate) { create(:estimate, account: account, client: client, status: :sent) }

    it "returns a successful response" do
      get estimates_path
      expect(response).to be_successful
    end

    it "displays estimates" do
      get estimates_path
      expect(response.body).to include(draft_estimate.estimate_number)
      expect(response.body).to include(sent_estimate.estimate_number)
    end

    context "with search filter" do
      it "filters estimates by search term" do
        draft_estimate.update!(estimate_number: "EST-UNIQUE")
        get estimates_path, params: { search: "UNIQUE" }
        expect(response.body).to include("EST-UNIQUE")
        expect(response.body).not_to include(sent_estimate.estimate_number)
      end
    end

    context "with status filter" do
      it "filters estimates by status" do
        get estimates_path, params: { status: "draft" }
        expect(response.body).to include(draft_estimate.estimate_number)
        expect(response.body).not_to include(sent_estimate.estimate_number)
      end
    end
  end

  describe "GET /estimates/new" do
    it "returns a successful response" do
      get new_estimate_path
      expect(response).to be_successful
    end

    it "pre-selects client when provided" do
      get new_estimate_path, params: { client_id: client.id }
      expect(response).to be_successful
    end
  end

  describe "GET /estimates/:id" do
    let(:estimate) { create(:estimate, account: account, client: client) }

    it "returns a successful response" do
      get estimate_path(estimate)
      expect(response).to be_successful
    end
  end

  describe "POST /estimates" do
    let(:valid_attributes) do
      {
        client_id: client.id,
        issue_date: Date.current,
        valid_until: Date.current + 30.days,
        notes: "Test notes",
        line_items_attributes: [
          { description: "Service 1", quantity: 1, unit_price: 100 }
        ]
      }
    end

    context "with valid parameters" do
      it "creates a new Estimate" do
        expect {
          post estimates_path, params: { estimate: valid_attributes }
        }.to change(Estimate, :count).by(1)
      end

      it "redirects to estimates index" do
        post estimates_path, params: { estimate: valid_attributes }
        expect(response).to redirect_to(estimates_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { client_id: nil } }

      it "does not create a new Estimate" do
        expect {
          post estimates_path, params: { estimate: invalid_attributes }
        }.not_to change(Estimate, :count)
      end

      it "renders the new template" do
        post estimates_path, params: { estimate: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /estimates/:id/edit" do
    let(:estimate) { create(:estimate, account: account, client: client) }

    it "returns a successful response" do
      get edit_estimate_path(estimate)
      expect(response).to be_successful
    end
  end

  describe "PATCH /estimates/:id" do
    let(:estimate) { create(:estimate, account: account, client: client) }

    context "with valid parameters" do
      let(:new_attributes) { { notes: "Updated notes" } }

      it "updates the estimate" do
        patch estimate_path(estimate), params: { estimate: new_attributes }
        estimate.reload
        expect(estimate.notes).to eq("Updated notes")
      end

      it "redirects to estimates index" do
        patch estimate_path(estimate), params: { estimate: new_attributes }
        expect(response).to redirect_to(estimates_path)
      end
    end
  end

  describe "DELETE /estimates/:id" do
    context "when estimate is draft" do
      let!(:estimate) { create(:estimate, account: account, client: client, status: :draft) }

      it "destroys the estimate" do
        expect {
          delete estimate_path(estimate)
        }.to change(Estimate, :count).by(-1)
      end

      it "redirects to estimates index" do
        delete estimate_path(estimate)
        expect(response).to redirect_to(estimates_path)
      end
    end

    context "when estimate is sent" do
      let!(:estimate) { create(:estimate, :sent, account: account, client: client) }

      it "does not destroy the estimate" do
        expect {
          delete estimate_path(estimate)
        }.not_to change(Estimate, :count)
      end
    end
  end

  describe "POST /estimates/:id/send_estimate" do
    let(:estimate) { create(:estimate, account: account, client: client, status: :draft) }

    it "marks the estimate as sent" do
      post send_estimate_estimate_path(estimate)
      estimate.reload
      expect(estimate.status).to eq("sent")
    end

    it "redirects to estimates index" do
      post send_estimate_estimate_path(estimate)
      expect(response).to redirect_to(estimates_path)
    end
  end

  describe "POST /estimates/:id/accept" do
    let(:estimate) { create(:estimate, :sent, account: account, client: client) }

    it "marks the estimate as accepted" do
      post accept_estimate_path(estimate)
      estimate.reload
      expect(estimate.status).to eq("accepted")
    end
  end

  describe "POST /estimates/:id/decline" do
    let(:estimate) { create(:estimate, :sent, account: account, client: client) }

    it "marks the estimate as declined" do
      post decline_estimate_path(estimate)
      estimate.reload
      expect(estimate.status).to eq("declined")
    end
  end

  describe "POST /estimates/:id/convert_to_invoice" do
    let(:estimate) { create(:estimate, :accepted, account: account, client: client) }
    let!(:line_item) { create(:estimate_line_item, estimate: estimate, description: "Service", quantity: 1, unit_price: 100) }

    it "creates a new invoice" do
      expect {
        post convert_to_invoice_estimate_path(estimate)
      }.to change(Invoice, :count).by(1)
    end

    it "marks the estimate as converted" do
      post convert_to_invoice_estimate_path(estimate)
      estimate.reload
      expect(estimate.status).to eq("converted")
    end

    it "redirects to the new invoice" do
      post convert_to_invoice_estimate_path(estimate)
      expect(response).to redirect_to(invoice_path(Invoice.last))
    end
  end
end
