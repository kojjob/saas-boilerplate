# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExportPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user, :confirmed) }
  let(:admin_user) { create(:user, :confirmed) }
  let(:member_user) { create(:user, :confirmed) }
  let(:guest_user) { create(:user, :confirmed) }
  let(:non_member_user) { create(:user, :confirmed) }

  before do
    create(:membership, user: owner_user, account: account, role: "owner")
    create(:membership, user: admin_user, account: account, role: "admin")
    create(:membership, user: member_user, account: account, role: "member")
    create(:membership, user: guest_user, account: account, role: "guest")
    ActsAsTenant.current_tenant = account
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  # ExportPolicy uses :export as a symbol record (not a model instance)
  # since exports are not persisted - they're generated on-demand
  subject { described_class.new(user, :export) }

  describe "owner" do
    let(:user) { owner_user }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:create) }
  end

  describe "admin" do
    let(:user) { admin_user }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:create) }
  end

  describe "member" do
    let(:user) { member_user }

    # Members should be able to export data for accounting purposes
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:create) }
  end

  describe "guest" do
    let(:user) { guest_user }

    # Guests should not be able to export sensitive financial data
    it { is_expected.not_to permit_action(:new) }
    it { is_expected.not_to permit_action(:create) }
  end

  describe "non-member" do
    let(:user) { non_member_user }

    it { is_expected.not_to permit_action(:new) }
    it { is_expected.not_to permit_action(:create) }
  end
end
