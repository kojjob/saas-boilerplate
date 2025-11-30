# frozen_string_literal: true

# Rack::Attack Configuration
# Protect against brute force attacks, DDoS, and abusive clients
#
# For more information, see: https://github.com/rack/rack-attack

class Rack::Attack
  ### Configure Cache ###

  # Use Rails cache store for Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Strategies ###

  # Throttle all requests by IP (300 requests per 5 minutes)
  # This provides general protection against aggressive crawlers or scrapers
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle login attempts by IP address (5 attempts per 20 seconds)
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address (5 attempts per 5 minutes)
  throttle("logins/email", limit: 5, period: 5.minutes) do |req|
    if req.path == "/sign_in" && req.post?
      # Normalize email to prevent bypassing by using variations
      req.params.dig("user", "email")&.to_s&.downcase&.strip&.gsub(/\s/, "")
    end
  end

  # Throttle password reset requests by IP (5 requests per hour)
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/password/reset" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests by email (3 requests per hour)
  throttle("password_reset/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/password/reset" && req.post?
      req.params.dig("user", "email")&.to_s&.downcase&.strip
    end
  end

  # Throttle registration attempts by IP (10 per hour)
  throttle("registrations/ip", limit: 10, period: 1.hour) do |req|
    if req.path == "/sign_up" && req.post?
      req.ip
    end
  end

  # Throttle API token requests (20 per minute per IP)
  throttle("api/token/ip", limit: 20, period: 1.minute) do |req|
    if req.path == "/api/v1/auth/token" && req.post?
      req.ip
    end
  end

  # Throttle API requests by token (100 per minute)
  throttle("api/requests", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      # Use API token or IP for throttling
      req.env["HTTP_AUTHORIZATION"]&.gsub("Bearer ", "") || req.ip
    end
  end

  ### Blocklist IPs ###

  # Block requests from localhost in production (customize as needed)
  # blocklist("block localhost") do |req|
  #   Rails.env.production? && req.ip == "127.0.0.1"
  # end

  # Block IPs in a blocklist stored in cache
  blocklist("block bad IPs") do |req|
    Rack::Attack.cache.read("blocked:#{req.ip}")
  end

  ### Safelist ###

  # Always allow requests from localhost in development/test
  safelist("allow localhost in dev") do |req|
    !Rails.env.production? && [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  # Allow admins or known good IPs to bypass rate limiting
  safelist("allow admins") do |req|
    # Add your admin IPs or implement admin detection logic
    # req.ip == "YOUR_ADMIN_IP"
    false
  end

  ### Custom Responses ###

  # Customize throttled response
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s,
      "X-RateLimit-Limit" => match_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + retry_after).to_s
    }

    body = {
      error: "Rate limit exceeded",
      message: "Too many requests. Please retry after #{retry_after} seconds.",
      retry_after: retry_after
    }.to_json

    [ 429, headers, [ body ] ]
  end

  # Customize blocklist response
  self.blocklisted_responder = lambda do |env|
    body = {
      error: "Forbidden",
      message: "Your IP has been blocked due to suspicious activity."
    }.to_json

    [ 403, { "Content-Type" => "application/json" }, [ body ] ]
  end

  ### Logging ###

  # Log throttled requests
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    request = payload[:request]
    Rails.logger.warn(
      "[Rack::Attack] Throttled #{request.ip} - " \
      "Path: #{request.path} - " \
      "Discriminator: #{payload[:match_discriminator]}"
    )
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    request = payload[:request]
    Rails.logger.warn(
      "[Rack::Attack] Blocked #{request.ip} - " \
      "Path: #{request.path}"
    )
  end
end

# Helper method to block an IP programmatically
# Usage: Rack::Attack::BlockedIp.block("1.2.3.4", 1.hour)
module Rack
  class Attack
    module BlockedIp
      def self.block(ip, duration = 1.hour)
        Rack::Attack.cache.write("blocked:#{ip}", true, expires_in: duration)
      end

      def self.unblock(ip)
        Rack::Attack.cache.delete("blocked:#{ip}")
      end

      def self.blocked?(ip)
        Rack::Attack.cache.read("blocked:#{ip}").present?
      end
    end
  end
end
