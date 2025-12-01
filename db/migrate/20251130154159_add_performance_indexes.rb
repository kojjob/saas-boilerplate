# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Composite index for filtering memberships by account and role
    add_index :memberships, [:account_id, :role], if_not_exists: true

    # Index for sorting users by creation date (admin dashboard, reporting)
    add_index :users, :created_at, if_not_exists: true

    # Index for sorting accounts by creation date (admin dashboard, reporting)
    add_index :accounts, :created_at, if_not_exists: true

    # Index for filtering accounts by subscription status
    add_index :accounts, :subscription_status, if_not_exists: true

    # Index for filtering notifications by read status
    add_index :notifications, :read_at, if_not_exists: true
  end
end
