# frozen_string_literal: true

require "rails_helper"

RSpec.describe Client, type: :model do
  describe "associations" do
    it { should belong_to(:account) }
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:client) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).scoped_to(:account_id).case_insensitive }

    it "validates email format" do
      client = build(:client, email: "invalid-email")
      expect(client).not_to be_valid
      expect(client.errors[:email]).to include("is invalid")
    end

    it "allows valid phone numbers" do
      client = build(:client, phone: "+1-555-123-4567")
      expect(client).to be_valid
    end
  end

  describe "normalizations" do
    it "normalizes email to lowercase and strips whitespace" do
      client = create(:client, email: "  TEST@Example.COM  ")
      expect(client.email).to eq("test@example.com")
    end

    it "strips whitespace from name" do
      client = create(:client, name: "  John Doe  ")
      expect(client.name).to eq("John Doe")
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let!(:active_client) { create(:client, account: account, status: :active) }
    let!(:archived_client) { create(:client, account: account, status: :archived) }

    describe ".active" do
      it "returns only active clients" do
        expect(Client.active).to include(active_client)
        expect(Client.active).not_to include(archived_client)
      end
    end

    describe ".archived" do
      it "returns only archived clients" do
        expect(Client.archived).to include(archived_client)
        expect(Client.archived).not_to include(active_client)
      end
    end

    describe ".search" do
      it "finds clients by name" do
        client_with_name = create(:client, account: account, name: "John Doe")
        expect(Client.search("John")).to include(client_with_name)
      end

      it "finds clients by email" do
        expect(Client.search(active_client.email)).to include(active_client)
      end

      it "finds clients by company" do
        client_with_company = create(:client, account: account, company: "Acme Corp")
        expect(Client.search("Acme")).to include(client_with_company)
      end
    end
  end

  describe "instance methods" do
    describe "#full_address" do
      it "returns formatted address when all fields present" do
        client = build(:client,
          address_line1: "123 Main St",
          address_line2: "Suite 100",
          city: "New York",
          state: "NY",
          postal_code: "10001",
          country: "USA"
        )
        expect(client.full_address).to eq("123 Main St, Suite 100, New York, NY 10001, USA")
      end

      it "handles missing address fields gracefully" do
        client = build(:client, city: "New York", state: "NY")
        expect(client.full_address).to eq("New York, NY")
      end

      it "returns nil when no address fields present" do
        client = build(:client)
        expect(client.full_address).to be_nil
      end
    end

    describe "#display_name" do
      it "returns company name if present" do
        client = build(:client, name: "John Doe", company: "Acme Corp")
        expect(client.display_name).to eq("Acme Corp")
      end

      it "returns name if no company" do
        client = build(:client, name: "John Doe", company: nil)
        expect(client.display_name).to eq("John Doe")
      end
    end

    describe "#archive!" do
      it "sets status to archived" do
        client = create(:client, status: :active)
        client.archive!
        expect(client.reload.status).to eq("archived")
      end
    end

    describe "#activate!" do
      it "sets status to active" do
        client = create(:client, status: :archived)
        client.activate!
        expect(client.reload.status).to eq("active")
      end
    end

    describe "#total_revenue" do
      it "returns sum of paid invoice amounts" do
        client = create(:client)
        create(:invoice, client: client, account: client.account, status: :paid, total_amount: 1000)
        create(:invoice, client: client, account: client.account, status: :paid, total_amount: 500)
        create(:invoice, client: client, account: client.account, status: :sent, total_amount: 300) # Not paid

        expect(client.total_revenue).to eq(1500)
      end

      it "returns 0 when no paid invoices" do
        client = create(:client)
        expect(client.total_revenue).to eq(0)
      end
    end

    describe "#outstanding_balance" do
      it "returns sum of unpaid invoice amounts" do
        client = create(:client)
        create(:invoice, client: client, account: client.account, status: :sent, total_amount: 1000)
        create(:invoice, client: client, account: client.account, status: :overdue, total_amount: 500)
        create(:invoice, client: client, account: client.account, status: :paid, total_amount: 300) # Paid

        expect(client.outstanding_balance).to eq(1500)
      end
    end

    describe "#initials" do
      it "returns first letters of first and last name" do
        client = build(:client, name: "John Doe")
        expect(client.initials).to eq("JD")
      end

      it "returns first two letters for single name" do
        client = build(:client, name: "John")
        expect(client.initials).to eq("JO")
      end

      it "returns ?? for blank name" do
        client = build(:client, name: "")
        expect(client.initials).to eq("??")
      end
    end
  end

  describe "portal token functionality" do
    describe "#generate_portal_token!" do
      it "generates a secure random token" do
        client = create(:client)
        expect { client.generate_portal_token! }.to change { client.portal_token }.from(nil)
        expect(client.portal_token).to be_present
        expect(client.portal_token.length).to eq(32)
      end

      it "sets portal_token_generated_at timestamp" do
        client = create(:client)
        freeze_time do
          client.generate_portal_token!
          expect(client.portal_token_generated_at).to eq(Time.current)
        end
      end

      it "generates unique tokens for different clients" do
        client1 = create(:client)
        client2 = create(:client)

        client1.generate_portal_token!
        client2.generate_portal_token!

        expect(client1.portal_token).not_to eq(client2.portal_token)
      end
    end

    describe "#regenerate_portal_token!" do
      it "replaces existing token with new one" do
        client = create(:client)
        client.generate_portal_token!
        old_token = client.portal_token

        client.regenerate_portal_token!
        expect(client.portal_token).not_to eq(old_token)
      end

      it "updates portal_token_generated_at" do
        client = create(:client)
        client.generate_portal_token!
        old_time = client.portal_token_generated_at

        travel_to 1.hour.from_now do
          client.regenerate_portal_token!
          expect(client.portal_token_generated_at).to be > old_time
        end
      end
    end

    describe "#revoke_portal_token!" do
      it "clears the portal token" do
        client = create(:client)
        client.generate_portal_token!

        client.revoke_portal_token!
        expect(client.portal_token).to be_nil
        expect(client.portal_token_generated_at).to be_nil
      end
    end

    describe "#portal_url" do
      it "returns the portal URL with token" do
        client = create(:client)
        client.generate_portal_token!

        expect(client.portal_url).to include("/portal/#{client.portal_token}")
      end

      it "returns nil if no token exists" do
        client = create(:client)
        expect(client.portal_url).to be_nil
      end
    end

    describe "#portal_access_enabled?" do
      it "returns true when portal_enabled is true and token exists" do
        client = create(:client, portal_enabled: true)
        client.generate_portal_token!

        expect(client.portal_access_enabled?).to be true
      end

      it "returns false when portal_enabled is false" do
        client = create(:client, portal_enabled: false)
        client.generate_portal_token!

        expect(client.portal_access_enabled?).to be false
      end

      it "returns false when no token exists" do
        client = create(:client, portal_enabled: true)
        expect(client.portal_access_enabled?).to be false
      end
    end

    describe ".find_by_portal_token" do
      it "finds client by valid token" do
        client = create(:client)
        client.generate_portal_token!

        found = Client.find_by_portal_token(client.portal_token)
        expect(found).to eq(client)
      end

      it "returns nil for invalid token" do
        expect(Client.find_by_portal_token("invalid_token")).to be_nil
      end

      it "returns nil for disabled portal access" do
        client = create(:client, portal_enabled: false)
        client.generate_portal_token!

        expect(Client.find_by_portal_token(client.portal_token)).to be_nil
      end
    end
  end
end
