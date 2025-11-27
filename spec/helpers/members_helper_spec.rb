# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembersHelper, type: :helper do
  describe "#role_badge_class" do
    it "returns purple classes for owner role" do
      expect(helper.role_badge_class("owner")).to eq("bg-purple-100 text-purple-800")
    end

    it "returns blue classes for admin role" do
      expect(helper.role_badge_class("admin")).to eq("bg-blue-100 text-blue-800")
    end

    it "returns green classes for member role" do
      expect(helper.role_badge_class("member")).to eq("bg-green-100 text-green-800")
    end

    it "returns gray classes for guest role" do
      expect(helper.role_badge_class("guest")).to eq("bg-gray-100 text-gray-800")
    end

    it "returns gray classes for unknown roles" do
      expect(helper.role_badge_class("unknown")).to eq("bg-gray-100 text-gray-800")
    end

    it "handles symbol roles" do
      expect(helper.role_badge_class(:owner)).to eq("bg-purple-100 text-purple-800")
    end
  end

  describe "#available_roles_for_select" do
    let(:account) { create(:account) }

    context "when current membership is owner" do
      let(:owner_membership) { create(:membership, account: account, role: "owner") }

      it "returns admin, member, and guest options" do
        roles = helper.available_roles_for_select(owner_membership)
        expect(roles).to eq([ [ "Admin", "admin" ], [ "Member", "member" ], [ "Guest", "guest" ] ])
      end
    end

    context "when current membership is admin" do
      let(:admin_membership) { create(:membership, account: account, role: "admin") }

      it "returns member and guest options only" do
        roles = helper.available_roles_for_select(admin_membership)
        expect(roles).to eq([ [ "Member", "member" ], [ "Guest", "guest" ] ])
      end
    end

    context "when current membership is member" do
      let(:member_membership) { create(:membership, account: account, role: "member") }

      it "returns member and guest options only" do
        roles = helper.available_roles_for_select(member_membership)
        expect(roles).to eq([ [ "Member", "member" ], [ "Guest", "guest" ] ])
      end
    end

    context "when current membership is nil" do
      it "returns member and guest options only" do
        roles = helper.available_roles_for_select(nil)
        expect(roles).to eq([ [ "Member", "member" ], [ "Guest", "guest" ] ])
      end
    end
  end
end
