# frozen_string_literal: true

class AddLastActiveAtIndexToSessions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Index for session cleanup queries (finding old/inactive sessions)
    add_index :sessions, :last_active_at, algorithm: :concurrently, if_not_exists: true
  end
end
