# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy, type: :policy do
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
    let(:project) { create(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:index) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:index) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to permit_action(:index) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to permit_action(:index) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, project) }
      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "show?" do
    let(:project) { create(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:show) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:show) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to permit_action(:show) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to permit_action(:show) }
    end

    context "as non-member" do
      subject { described_class.new(non_member, project) }
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe "create?" do
    let(:project) { build(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:create) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:create) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to forbid_action(:create) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to forbid_action(:create) }
    end
  end

  describe "new?" do
    let(:project) { build(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:new) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:new) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to forbid_action(:new) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to forbid_action(:new) }
    end
  end

  describe "update?" do
    let(:project) { create(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:update) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:update) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to forbid_action(:update) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "edit?" do
    let(:project) { create(:project, account: account, client: client) }

    context "as owner" do
      subject { described_class.new(owner, project) }
      it { is_expected.to permit_action(:edit) }
    end

    context "as admin" do
      subject { described_class.new(admin, project) }
      it { is_expected.to permit_action(:edit) }
    end

    context "as member" do
      subject { described_class.new(member, project) }
      it { is_expected.to forbid_action(:edit) }
    end

    context "as guest" do
      subject { described_class.new(guest, project) }
      it { is_expected.to forbid_action(:edit) }
    end
  end

  describe "destroy?" do
    context "when project is draft" do
      let(:project) { create(:project, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:destroy) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to permit_action(:destroy) }
      end

      context "as member" do
        subject { described_class.new(member, project) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "as guest" do
        subject { described_class.new(guest, project) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when project is active" do
      let(:project) { create(:project, :active, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when project is completed" do
      let(:project) { create(:project, :completed, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when project is on_hold" do
      let(:project) { create(:project, :on_hold, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context "when project is cancelled" do
      let(:project) { create(:project, :cancelled, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end
  end

  describe "archive?" do
    context "when project is not completed" do
      let(:project) { create(:project, :active, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:archive) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to permit_action(:archive) }
      end

      context "as member" do
        subject { described_class.new(member, project) }
        it { is_expected.to forbid_action(:archive) }
      end

      context "as guest" do
        subject { described_class.new(guest, project) }
        it { is_expected.to forbid_action(:archive) }
      end
    end

    context "when project is draft" do
      let(:project) { create(:project, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:archive) }
      end
    end

    context "when project is on_hold" do
      let(:project) { create(:project, :on_hold, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:archive) }
      end
    end

    context "when project is completed" do
      let(:project) { create(:project, :completed, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:archive) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to forbid_action(:archive) }
      end
    end
  end

  describe "complete?" do
    context "when project is not completed" do
      let(:project) { create(:project, :active, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:complete) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to permit_action(:complete) }
      end

      context "as member" do
        subject { described_class.new(member, project) }
        it { is_expected.to forbid_action(:complete) }
      end

      context "as guest" do
        subject { described_class.new(guest, project) }
        it { is_expected.to forbid_action(:complete) }
      end
    end

    context "when project is draft" do
      let(:project) { create(:project, :draft, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:complete) }
      end
    end

    context "when project is on_hold" do
      let(:project) { create(:project, :on_hold, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to permit_action(:complete) }
      end
    end

    context "when project is already completed" do
      let(:project) { create(:project, :completed, account: account, client: client) }

      context "as owner" do
        subject { described_class.new(owner, project) }
        it { is_expected.to forbid_action(:complete) }
      end

      context "as admin" do
        subject { described_class.new(admin, project) }
        it { is_expected.to forbid_action(:complete) }
      end
    end
  end

  describe "Scope" do
    let!(:account_project) { create(:project, account: account, client: client) }
    let(:other_account) { create(:account) }
    let(:other_client) { create(:client, account: other_account) }
    let!(:other_project) { create(:project, account: other_account, client: other_client) }

    subject { described_class::Scope.new(owner, Project.all).resolve }

    it "includes projects from the current account" do
      expect(subject).to include(account_project)
    end

    it "excludes projects from other accounts" do
      expect(subject).not_to include(other_project)
    end
  end
end
