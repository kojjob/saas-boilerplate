# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should have_secure_password }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:accounts).through(:memberships) }
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe 'email normalization' do
    it 'normalizes email to lowercase and strips whitespace' do
      user = create(:user, email: '  TEST@Example.COM  ')
      expect(user.email).to eq('test@example.com')
    end
  end

  describe 'email validation' do
    it 'accepts valid email formats' do
      valid_emails = %w[user@example.com user.name@example.com user+tag@example.co.uk]
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid, "Expected #{email} to be valid"
      end
    end

    it 'rejects invalid email formats' do
      invalid_emails = %w[invalid @example.com user@ user@.com]
      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid, "Expected #{email} to be invalid"
      end
    end
  end

  describe '#full_name' do
    it 'returns the first and last name combined' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#initials' do
    it 'returns the first letter of first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.initials).to eq('JD')
    end
  end

  describe 'confirmation' do
    it 'generates a confirmation token on creation' do
      user = create(:user)
      expect(user.confirmation_token).to be_present
    end

    it 'is not confirmed by default' do
      user = create(:user)
      expect(user.confirmed?).to be false
    end

    describe '#confirm!' do
      it 'sets confirmed_at and clears the confirmation token' do
        user = create(:user)
        user.confirm!
        expect(user.confirmed?).to be true
        expect(user.confirmation_token).to be_nil
      end
    end
  end

  describe 'password reset' do
    describe '#generate_password_reset_token!' do
      it 'generates a reset token and sets sent_at timestamp' do
        user = create(:user)
        user.generate_password_reset_token!
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#password_reset_expired?' do
      it 'returns true after 2 hours' do
        user = create(:user, reset_password_sent_at: 3.hours.ago)
        expect(user.password_reset_expired?).to be true
      end

      it 'returns false within 2 hours' do
        user = create(:user, reset_password_sent_at: 1.hour.ago)
        expect(user.password_reset_expired?).to be false
      end
    end

    describe '#clear_password_reset_token!' do
      it 'clears the reset token and timestamp' do
        user = create(:user)
        user.generate_password_reset_token!
        user.clear_password_reset_token!
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end
    end
  end

  describe '#membership_for' do
    let(:user) { create(:user) }
    let(:account) { create(:account) }

    it 'returns the membership for the given account' do
      membership = create(:membership, user: user, account: account, role: :admin)
      expect(user.membership_for(account)).to eq(membership)
    end

    it 'returns nil if no membership exists' do
      expect(user.membership_for(account)).to be_nil
    end
  end

  describe '#role_for' do
    let(:user) { create(:user) }
    let(:account) { create(:account) }

    it 'returns the role for the given account' do
      create(:membership, user: user, account: account, role: :admin)
      expect(user.role_for(account)).to eq('admin')
    end

    it 'returns nil if no membership exists' do
      expect(user.role_for(account)).to be_nil
    end
  end
end
