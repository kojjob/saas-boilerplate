# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicePolicy, type: :policy do
  let(:account) { create(:account) }
  let(:owner) { create(:user, :confirmed) }
  let(:admin) { create(:user, :confirmed) }
  let(:member) { create(:user, :confirmed) }
  let(:guest) { create(:user, :confirmed) }
  let(:non_member) { create(:user, :confirmed) }

  let!(:owner_membership) { create(:membership, :owner, user: owner, account: account) }
  let!(:admin_membership) { create(:membership, user: admin, account: account, role: :admin) }
  let!(:member_membership) { create(:membership, user: member, account: account, role: :member) }
  let!(:guest_membership) { create(:membership, user: guest, account: account, role: :guest) }

  let(:client) { create(:client, account: account) }

  before do
    ActsAsTenant.current_tenant = account
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe "index?" do
    let(:invoice) { create(:invoice, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, invoice) }
      it { is_expected.to permit_action(:index) }
    end

    context "as admin" do
      subject { described_class.new(admin, invoice) }
      it { is_expected.to permit_action(:index) }
    end

    context "as member" do
      subject { described_class.new(member, invoice) }
      it { is_expected.to permit_action(:index) }
    end

    context "as guest" do
      subject { described_class.new(guest, invoice) }
      it { is_expected.to permit_action(:index) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, invoice) }
      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "show?" do
    let(:invoice) { create(:invoice, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, invoice) }
      it { is_expected.to permit_action(:show) }
    end

    context "as admin" do
      subject { described_class.new(admin, invoice) }
      it { is_expected.to permit_action(:show) }
    end

    context "as member" do
      subject { described_class.new(member, invoice) }
      it { is_expected.to permit_action(:show) }
    end

    context "as guest" do
      subject { described_class.new(guest, invoice) }
      it { is_expected.to permit_action(:show) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, invoice) }
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe "create?" do
    let(:invoice) { build(:invoice, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, invoice) }
      it { is_expected.to permit_action(:create) }
    end

    context "as admin" do
      subject { described_class.new(admin, invoice) }
      it { is_expected.to permit_action(:create) }
    end

    context "as member" do
      subject { described_class.new(member, invoice) }
      it { is_expected.to forbid_action(:create) }
    end

    context "as guest" do
      subject { described_class.new(guest, invoice) }
      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "update?" do
    context "when invoice is draft" do
      let(:invoice) { create(:invoice, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:update) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:update) }
      end

      context "as member" do
        subject { described_class.new(member, invoice) }
        it { is_expected.to forbid_action(:update) }
      end

      context "as guest" do
        subject { described_class.new(guest, invoice) }
        it { is_expected.to forbid_action(:update) }
      end
    end

    context "when invoice is sent" do
      let(:invoice) { create(:invoice, :sent, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:update) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:update) }
      end
    end

    context "when invoice is paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:update) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to forbid_action(:update) }
      end
    end
  end

  describe "destroy?" do
    context "when invoice is draft" do
      let(:invoice) { create(:invoice, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:destroy) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:destroy) }
      end

      context "as member" do
        subject { described_class.new(member, invoice) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "as guest" do
        subject { described_class.new(guest, invoice) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when invoice is sent" do
      let(:invoice) { create(:invoice, :sent, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when invoice is paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end
  end

  describe "send_invoice?" do
    context "when invoice is draft" do
      let(:invoice) { create(:invoice, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:send_invoice) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:send_invoice) }
      end

      context "as member" do
        subject { described_class.new(member, invoice) }
        it { is_expected.to forbid_action(:send_invoice) }
      end

      context "as guest" do
        subject { described_class.new(guest, invoice) }
        it { is_expected.to forbid_action(:send_invoice) }
      end
    end

    context "when invoice is already sent" do
      let(:invoice) { create(:invoice, :sent, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:send_invoice) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to forbid_action(:send_invoice) }
      end
    end

    context "when invoice is paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:send_invoice) }
      end
    end
  end

  describe "mark_paid?" do
    context "when invoice is payable (sent)" do
      let(:invoice) { create(:invoice, :sent, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:mark_paid) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:mark_paid) }
      end

      context "as member" do
        subject { described_class.new(member, invoice) }
        it { is_expected.to forbid_action(:mark_paid) }
      end

      context "as guest" do
        subject { described_class.new(guest, invoice) }
        it { is_expected.to forbid_action(:mark_paid) }
      end
    end

    context "when invoice is payable (viewed)" do
      let(:invoice) { create(:invoice, :viewed, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:mark_paid) }
      end
    end

    context "when invoice is payable (overdue)" do
      let(:invoice) { create(:invoice, :overdue, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:mark_paid) }
      end
    end

    context "when invoice is draft" do
      let(:invoice) { create(:invoice, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:mark_paid) }
      end
    end

    context "when invoice is already paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:mark_paid) }
      end
    end

    context "when invoice is cancelled" do
      let(:invoice) { create(:invoice, :cancelled, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:mark_paid) }
      end
    end
  end

  describe "mark_cancelled?" do
    context "when invoice is not paid" do
      let(:invoice) { create(:invoice, :sent, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:mark_cancelled) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to permit_action(:mark_cancelled) }
      end

      context "as member" do
        subject { described_class.new(member, invoice) }
        it { is_expected.to forbid_action(:mark_cancelled) }
      end

      context "as guest" do
        subject { described_class.new(guest, invoice) }
        it { is_expected.to forbid_action(:mark_cancelled) }
      end
    end

    context "when invoice is draft" do
      let(:invoice) { create(:invoice, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to permit_action(:mark_cancelled) }
      end
    end

    context "when invoice is paid" do
      let(:invoice) { create(:invoice, :paid, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, invoice) }
        it { is_expected.to forbid_action(:mark_cancelled) }
      end

      context "as admin" do
        subject { described_class.new(admin, invoice) }
        it { is_expected.to forbid_action(:mark_cancelled) }
      end
    end
  end

  describe "preview?" do
    let(:invoice) { create(:invoice, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, invoice) }
      it { is_expected.to permit_action(:preview) }
    end

    context "as admin" do
      subject { described_class.new(admin, invoice) }
      it { is_expected.to permit_action(:preview) }
    end

    context "as member" do
      subject { described_class.new(member, invoice) }
      it { is_expected.to permit_action(:preview) }
    end

    context "as guest" do
      subject { described_class.new(guest, invoice) }
      it { is_expected.to permit_action(:preview) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, invoice) }
      it { is_expected.to forbid_action(:preview) }
    end
  end

  describe "download?" do
    let(:invoice) { create(:invoice, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, invoice) }
      it { is_expected.to permit_action(:download) }
    end

    context "as admin" do
      subject { described_class.new(admin, invoice) }
      it { is_expected.to permit_action(:download) }
    end

    context "as member" do
      subject { described_class.new(member, invoice) }
      it { is_expected.to permit_action(:download) }
    end

    context "as guest" do
      subject { described_class.new(guest, invoice) }
      it { is_expected.to permit_action(:download) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, invoice) }
      it { is_expected.to forbid_action(:download) }
    end
  end

  describe "Scope" do
    let!(:account_invoice) { create(:invoice, account: account, client: client) }
    let(:other_account) { create(:account) }
    let(:other_client) { create(:client, account: other_account) }
    let!(:other_invoice) { create(:invoice, account: other_account, client: other_client) }

    subject { described_class::Scope.new(owner, Invoice.all).resolve }

    it "includes invoices from the current account" do
      expect(subject).to include(account_invoice)
    end

    it "excludes invoices from other accounts" do
      expect(subject).not_to include(other_invoice)
    end
  end
end
