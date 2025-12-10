# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClientPolicy, type: :policy do
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
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:index) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:index) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to permit_action(:index) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to permit_action(:index) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, client) }
      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "show?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:show) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:show) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to permit_action(:show) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to permit_action(:show) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, client) }
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe "create?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:create) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:create) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to forbid_action(:create) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "new?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:new) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:new) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to forbid_action(:new) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to forbid_action(:new) }
    end
  end

  describe "update?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:update) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:update) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to forbid_action(:update) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "edit?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:edit) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:edit) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to forbid_action(:edit) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to forbid_action(:edit) }
    end
  end

  describe "destroy?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  describe "projects?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:projects) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:projects) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to permit_action(:projects) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to permit_action(:projects) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, client) }
      it { is_expected.to forbid_action(:projects) }
    end
  end

  describe "invoices?" do
    context "as owner" do
      subject { described_class.new(owner, client) }
      it { is_expected.to permit_action(:invoices) }
    end

    context "as admin" do
      subject { described_class.new(admin, client) }
      it { is_expected.to permit_action(:invoices) }
    end

    context "as member" do
      subject { described_class.new(member, client) }
      it { is_expected.to permit_action(:invoices) }
    end

    context "as guest" do
      subject { described_class.new(guest, client) }
      it { is_expected.to permit_action(:invoices) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, client) }
      it { is_expected.to forbid_action(:invoices) }
    end
  end

  describe "Scope" do
    let!(:account_client) { create(:client, account: account) }
    let(:other_account) { create(:account) }
    let!(:other_client) { create(:client, account: other_account) }

    subject { described_class::Scope.new(owner, Client.all).resolve }

    it "includes clients from the current account" do
      expect(subject).to include(account_client)
    end

    it "excludes clients from other accounts" do
      expect(subject).not_to include(other_client)
    end
  end
end
