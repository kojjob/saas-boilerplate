#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

file = "coverage/.resultset.json"
unless File.exist?(file)
  puts "No coverage file found"
  exit 1
end

data = JSON.parse(File.read(file))
coverage_data = data["RSpec"]["coverage"] || {}

results = []
coverage_data.each do |path, info|
  lines = info["lines"] || []
  total = lines.compact.size
  covered = lines.count { |l| l && l > 0 }
  next if total == 0

  pct = (covered.to_f / total * 100).round(2)
  short_path = path.sub(Dir.pwd + "/", "")
  results << { path: short_path, pct: pct, total: total, covered: covered, missed: total - covered }
end

puts "\n=== Files with lowest coverage (bottom 25) ===\n\n"
results.sort_by { |r| r[:pct] }.first(25).each do |r|
  puts format("%6.2f%% | %3d missed | %s", r[:pct], r[:missed], r[:path])
end

total_lines = results.sum { |r| r[:total] }
covered_lines = results.sum { |r| r[:covered] }
overall = (covered_lines.to_f / total_lines * 100).round(2)

puts "\n=== Overall Coverage ===\n"
puts "#{covered_lines}/#{total_lines} lines covered (#{overall}%)"
puts "Need #{(total_lines * 0.9).ceil - covered_lines} more lines to reach 90%"
