# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auditable concern" do
  describe "audited models" do
    describe User do
      let(:user) { create(:user, :confirmed, :owner) }

      it "is audited" do
        expect(User.respond_to?(:audited)).to be true
      end

      it "creates an audit on create" do
        new_user = build(:user, :confirmed)
        expect { new_user.save! }.to change(Audited::Audit, :count).by(1)
      end

      it "creates an audit on update" do
        expect { user.update!(first_name: "Updated") }.to change { user.audits.count }.by(1)
      end

      it "records the changed attributes" do
        user.update!(first_name: "NewName")
        audit = user.audits.last

        expect(audit.audited_changes).to include("first_name")
      end

      it "tracks the user who made the change when set" do
        admin = create(:user, :confirmed, :owner)
        Audited.audit_class.as_user(admin) do
          user.update!(first_name: "Changed")
        end

        expect(user.audits.last.user).to eq(admin)
      end

      it "excludes sensitive attributes" do
        user.update!(password: "newpassword123", password_confirmation: "newpassword123")
        audit = user.audits.last

        expect(audit.audited_changes.keys).not_to include("password_digest")
        expect(audit.audited_changes.keys).not_to include("password")
      end
    end

    describe Account do
      let(:account) { create(:account) }

      it "is audited" do
        expect(Account.respond_to?(:audited)).to be true
      end

      it "creates an audit on update" do
        expect { account.update!(name: "Updated Name") }.to change { account.audits.count }.by(1)
      end

      it "records the changed attributes" do
        account.update!(name: "NewAccountName")
        audit = account.audits.last

        expect(audit.audited_changes).to include("name")
      end
    end

    describe Membership do
      let(:membership) { create(:membership) }

      it "is audited" do
        expect(Membership.respond_to?(:audited)).to be true
      end

      it "creates an audit on update" do
        expect { membership.update!(role: "admin") }.to change { membership.audits.count }.by(1)
      end

      it "records the changed attributes" do
        membership.update!(role: "admin")
        audit = membership.audits.last

        expect(audit.audited_changes).to include("role")
      end

      it "excludes invitation_token from audits" do
        membership.update!(invitation_token: SecureRandom.urlsafe_base64(32))
        audit = membership.audits.last

        expect(audit.audited_changes.keys).not_to include("invitation_token")
      end
    end
  end

  describe "audit associations" do
    let(:user) { create(:user, :confirmed, :owner) }

    it "provides access to audit history" do
      user.update!(first_name: "Changed")
      user.update!(last_name: "Updated")

      expect(user.audits.count).to be >= 2
    end

    it "can revert to a previous version" do
      original_name = user.first_name
      user.update!(first_name: "Changed")

      reverted_user = user.audits.first.revision
      expect(reverted_user.first_name).to eq(original_name)
    end
  end

  describe "audit querying" do
    let!(:user1) { create(:user, :confirmed, :owner) }
    let!(:user2) { create(:user, :confirmed, :owner) }

    before do
      user1.update!(first_name: "User1Updated")
      user2.update!(first_name: "User2Updated")
    end

    it "can query audits by auditable type" do
      user_audits = Audited::Audit.where(auditable_type: "User")
      expect(user_audits.count).to be >= 2
    end

    it "can query audits by action" do
      update_audits = Audited::Audit.where(action: "update")
      expect(update_audits.count).to be >= 2
    end

    it "can query audits by user" do
      admin = create(:user, :confirmed, :owner)
      Audited.audit_class.as_user(admin) do
        user1.update!(first_name: "AdminChanged")
      end

      admin_audits = Audited::Audit.where(user: admin)
      expect(admin_audits.count).to eq(1)
    end
  end
end
