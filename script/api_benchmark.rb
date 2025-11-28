#!/usr/bin/env ruby
require_relative '../config/environment'
require 'benchmark'

puts "=" * 80
puts "🚀 API & CONTROLLER PERFORMANCE ANALYSIS"
puts "=" * 80
puts "Rails #{Rails.version} | Ruby #{RUBY_VERSION} | #{Rails.env}"
puts "=" * 80

# Get test data
user = User.first
account = Account.first

puts "\n📊 Current Database State:"
puts "  Users: #{User.count}"
puts "  Accounts: #{Account.count}"
puts "  Memberships: #{Membership.count}"
puts "  Sessions: #{Session.count}"

puts "\n" + "=" * 80
puts "📈 CONTROLLER ACTION SIMULATION"
puts "=" * 80

iterations = 50

Benchmark.bm(50) do |x|
  # Simulate dashboard queries
  x.report("Dashboard data (accounts + memberships)") do
    iterations.times do
      if user
        user.accounts.includes(:memberships, :plan).to_a
      end
    end
  end

  # Simulate notification queries
  x.report("Unread notifications query") do
    iterations.times do
      Notification.where(read_at: nil).order(created_at: :desc).limit(20).to_a
    end
  end

  # Simulate session lookup
  x.report("Session by token lookup") do
    iterations.times do
      Session.includes(:user).where(user_id: user&.id).first
    end
  end

  # Simulate plan lookup
  x.report("Plan with features") do
    iterations.times do
      Plan.all.to_a
    end
  end
end

puts "\n" + "=" * 80
puts "🔍 QUERY COMPLEXITY ANALYSIS"
puts "=" * 80

# Analyze common query patterns
queries = {
  "Find user by email" => -> { User.find_by(email: user&.email) },
  "Find session by token" => -> { Session.joins(:user).first },
  "Account with associations" => -> { Account.includes(:memberships, :users, :plan).first },
  "Active accounts (scope)" => -> { Account.active.to_a },
  "User's notifications" => -> { Notification.where(user_id: user&.id).recent.to_a rescue [] }
}

queries.each do |name, query|
  time = Benchmark.measure { 100.times { query.call } }
  puts "#{name.ljust(35)} #{(time.real * 1000 / 100).round(2)}ms avg"
end

puts "\n" + "=" * 80
puts "💾 MEMORY EFFICIENT OPERATIONS"
puts "=" * 80

def memory_mb
  `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
end

initial = memory_mb

# Test find_each for batch processing
batch_count = 0
User.find_each(batch_size: 100) { |u| batch_count += 1 }
puts "find_each batch processing: #{batch_count} users processed"

# Test pluck for specific columns
emails = User.pluck(:email)
puts "pluck(:email): #{emails.count} emails retrieved efficiently"

# Test select for limited columns
users_lite = User.select(:id, :email, :first_name).to_a
puts "select(:id, :email, :first_name): #{users_lite.count} lite records"

after = memory_mb
puts "\nMemory delta: #{(after - initial).round(2)} MB"

puts "\n" + "=" * 80
puts "📊 PERFORMANCE RECOMMENDATIONS"
puts "=" * 80

recommendations = []

# Check for missing counter caches
if Account.column_names.include?('memberships_count')
  puts "✅ Counter cache exists for Account.memberships_count"
else
  recommendations << "⚠️  Consider adding counter_cache for Account.memberships"
end

# Check indexes on commonly queried columns
critical_indexes = [
  [ 'users', 'email' ],
  [ 'sessions', 'user_id' ],
  [ 'memberships', [ 'account_id', 'user_id' ] ],
  [ 'notifications', 'user_id' ]
]

critical_indexes.each do |table, columns|
  begin
    indexes = ActiveRecord::Base.connection.indexes(table)
    columns = Array(columns)
    has_index = indexes.any? { |idx| (columns - idx.columns).empty? }

    if has_index
      puts "✅ Index exists on #{table}(#{columns.join(', ')})"
    else
      recommendations << "⚠️  Missing index on #{table}(#{columns.join(', ')})"
    end
  rescue => e
    puts "❌ Error checking #{table}: #{e.message[0..50]}"
  end
end

puts "\n" + "-" * 40
if recommendations.empty?
  puts "✅ No critical performance issues detected"
else
  puts "Recommendations:"
  recommendations.each { |r| puts "  #{r}" }
end

puts "\n" + "=" * 80
puts "✅ API BENCHMARK COMPLETE"
puts "=" * 80
