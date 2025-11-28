#!/usr/bin/env ruby
require_relative '../config/environment'
require 'benchmark'

puts "=" * 80
puts "🚀 SAAS BOILERPLATE PERFORMANCE BENCHMARK"
puts "=" * 80
puts "Rails #{Rails.version} | Ruby #{RUBY_VERSION} | #{Rails.env}"
puts "Database: #{ActiveRecord::Base.connection.adapter_name}"
puts "=" * 80

# Count existing data
user_count = User.count
account_count = Account.count
membership_count = Membership.count
notification_count = Notification.count
session_count = Session.count

puts "\n📊 Current Database Records:"
puts "  Users: #{user_count}"
puts "  Accounts: #{account_count}"
puts "  Memberships: #{membership_count}"
puts "  Notifications: #{notification_count}"
puts "  Sessions: #{session_count}"

puts "\n" + "=" * 80
puts "📈 DATABASE QUERY BENCHMARKS"
puts "=" * 80

iterations = 100

Benchmark.bm(45) do |x|
  x.report("User.all.to_a") { iterations.times { User.all.to_a } }
  x.report("User.first") { iterations.times { User.first } }
  x.report("User.last") { iterations.times { User.last } }
  x.report("Account.all.to_a") { iterations.times { Account.all.to_a } }
  x.report("Account.includes(:memberships).to_a") { iterations.times { Account.includes(:memberships).all.to_a } }
  x.report("Account.includes(:plan).to_a") { iterations.times { Account.includes(:plan).all.to_a } }
  x.report("Membership.all.to_a") { iterations.times { Membership.all.to_a } }
  x.report("Membership.includes(:user).to_a") { iterations.times { Membership.includes(:user).all.to_a } }
  x.report("Membership.includes(:user, :account).to_a") { iterations.times { Membership.includes(:user, :account).all.to_a } }
  x.report("Notification.all.to_a") { iterations.times { Notification.all.to_a } }
end

puts "\n" + "=" * 80
puts "⚠️  N+1 QUERY DETECTION TEST"
puts "=" * 80

# Count queries helper
query_count = 0
query_log = []

counter = lambda do |*args|
  event = args[4]
  unless event[:name] == "SCHEMA" || event[:sql].include?("SAVEPOINT")
    query_count += 1
    query_log << event[:sql][0..80]
  end
end

ActiveSupport::Notifications.subscribe("sql.active_record", &counter)

puts "\n🔴 WITHOUT eager loading (Account -> memberships -> user):"
query_count = 0
query_log = []
time_without = Benchmark.measure do
  Account.all.each do |account|
    account.memberships.each do |m|
      m.user&.email
    end
  end
end
queries_without = query_count
puts "  Queries executed: #{queries_without}"
puts "  Time: #{(time_without.real * 1000).round(2)}ms"

puts "\n🟢 WITH eager loading:"
query_count = 0
query_log = []
time_with = Benchmark.measure do
  Account.includes(memberships: :user).all.each do |account|
    account.memberships.each do |m|
      m.user&.email
    end
  end
end
queries_with = query_count
puts "  Queries executed: #{queries_with}"
puts "  Time: #{(time_with.real * 1000).round(2)}ms"

if queries_without > queries_with
  improvement = ((queries_without - queries_with).to_f / queries_without * 100).round(1)
  puts "\n  📊 Improvement: #{improvement}% fewer queries (#{queries_without} → #{queries_with})"
end

ActiveSupport::Notifications.unsubscribe(counter)

puts "\n" + "=" * 80
puts "💾 CACHING BENCHMARKS"
puts "=" * 80

cache_iterations = 1000

Benchmark.bm(45) do |x|
  test_data = { test: "data", number: 123, array: [ 1, 2, 3 ] }

  x.report("Cache.write (#{cache_iterations}x)") do
    cache_iterations.times { |i| Rails.cache.write("bench_#{i}", test_data) }
  end

  x.report("Cache.read hit (#{cache_iterations}x)") do
    cache_iterations.times { |i| Rails.cache.read("bench_#{i}") }
  end

  x.report("Cache.read miss (#{cache_iterations}x)") do
    cache_iterations.times { |i| Rails.cache.read("nonexistent_#{i}") }
  end

  x.report("Cache.fetch hit (#{cache_iterations}x)") do
    cache_iterations.times { |i| Rails.cache.fetch("bench_#{i}") { test_data } }
  end

  x.report("Cache.delete (#{cache_iterations}x)") do
    cache_iterations.times { |i| Rails.cache.delete("bench_#{i}") }
  end
end

puts "\n" + "=" * 80
puts "🔐 AUTHENTICATION BENCHMARKS"
puts "=" * 80

user = User.first
if user
  Benchmark.bm(45) do |x|
    x.report("BCrypt.authenticate (correct pwd) 10x") do
      10.times { user.authenticate("password123") }
    end

    x.report("BCrypt.authenticate (wrong pwd) 10x") do
      10.times { user.authenticate("wrongpassword") }
    end

    x.report("SecureRandom.urlsafe_base64(32) 100x") do
      100.times { SecureRandom.urlsafe_base64(32) }
    end

    x.report("Digest::SHA256.hexdigest 1000x") do
      1000.times { Digest::SHA256.hexdigest("test_token_#{rand}") }
    end
  end
else
  puts "⚠️  No users found, skipping authentication benchmarks"
end

puts "\n" + "=" * 80
puts "📧 MODEL INSTANTIATION BENCHMARKS"
puts "=" * 80

Benchmark.bm(45) do |x|
  x.report("User.new (1000x)") do
    1000.times { User.new(email: "test@test.com", password: "test1234") }
  end

  x.report("Account.new (1000x)") do
    1000.times { Account.new(name: "Test Account") }
  end

  x.report("User.valid? (100x)") do
    100.times { User.new(email: "test#{rand(10000)}@test.com", password: "test1234", first_name: "Test", last_name: "User").valid? }
  end
end

puts "\n" + "=" * 80
puts "📊 INDEX ANALYSIS"
puts "=" * 80

puts "\nDatabase indexes by table:"
%w[users accounts memberships notifications sessions plans api_tokens].each do |table|
  begin
    indexes = ActiveRecord::Base.connection.indexes(table)
    puts "\n#{table}:"
    if indexes.empty?
      puts "  ⚠️  No custom indexes"
    else
      indexes.each do |idx|
        unique = idx.unique ? " (UNIQUE)" : ""
        puts "  ✅ #{idx.name}: [#{idx.columns.join(', ')}]#{unique}"
      end
    end
  rescue => e
    puts "  ❌ Error: #{e.message}"
  end
end

puts "\n" + "=" * 80
puts "🔍 QUERY PLAN ANALYSIS"
puts "=" * 80

queries = [
  [ "User by email", "SELECT * FROM users WHERE email = 'test@example.com' LIMIT 1" ],
  [ "Memberships by account", "SELECT * FROM memberships WHERE account_id = 1" ],
  [ "Notifications unread", "SELECT * FROM notifications WHERE read_at IS NULL ORDER BY created_at DESC LIMIT 20" ],
  [ "Sessions by user", "SELECT * FROM sessions WHERE user_id = 1 ORDER BY created_at DESC" ]
]

queries.each do |name, sql|
  puts "\n📌 #{name}:"
  begin
    result = ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
    result.each { |row| puts "   #{row['QUERY PLAN']}" }
  rescue => e
    puts "   ⚠️  #{e.message[0..60]}"
  end
end

puts "\n" + "=" * 80
puts "💻 MEMORY USAGE"
puts "=" * 80

def memory_mb
  `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
end

initial = memory_mb
puts "Initial: #{initial.round(2)} MB"

# Load some data
users = User.includes(:accounts, :memberships).all.to_a
after_load = memory_mb
puts "After loading users with associations: #{after_load.round(2)} MB (+#{(after_load - initial).round(2)} MB)"

users = nil
GC.start
after_gc = memory_mb
puts "After GC: #{after_gc.round(2)} MB"

puts "\n" + "=" * 80
puts "📈 PERFORMANCE SUMMARY"
puts "=" * 80

puts <<~SUMMARY

  Database Records:
  ├── Users: #{user_count}
  ├── Accounts: #{account_count}
  ├── Memberships: #{membership_count}
  ├── Notifications: #{notification_count}
  └── Sessions: #{session_count}

  N+1 Query Analysis:
  ├── Without eager loading: #{queries_without} queries
  ├── With eager loading: #{queries_with} queries
  └── Potential savings: #{queries_without > queries_with ? "#{((queries_without - queries_with).to_f / queries_without * 100).round(1)}%" : "N/A"}

  Recommendations:
SUMMARY

# Generate recommendations
recommendations = []

if queries_without > queries_with * 1.5
  recommendations << "⚠️  HIGH: Add eager loading to reduce N+1 queries"
end

if user_count == 0
  recommendations << "ℹ️  INFO: No test data - run db:seed for accurate benchmarks"
end

# Check for missing indexes
%w[users accounts memberships notifications].each do |table|
  indexes = ActiveRecord::Base.connection.indexes(table) rescue []
  if indexes.length < 2
    recommendations << "⚠️  MEDIUM: Consider adding more indexes to #{table}"
  end
end

if recommendations.empty?
  puts "  ✅ No critical performance issues detected"
else
  recommendations.each { |r| puts "  #{r}" }
end

puts "\n" + "=" * 80
puts "✅ BENCHMARK COMPLETE"
puts "=" * 80
