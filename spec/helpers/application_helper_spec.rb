# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#render_subscription_badge" do
    it "returns a badge with correct classes for trialing status" do
      badge = helper.render_subscription_badge(:trialing)
      expect(badge).to include("bg-blue-100")
      expect(badge).to include("text-blue-800")
      expect(badge).to include("Trialing")
    end

    it "returns a badge with correct classes for active status" do
      badge = helper.render_subscription_badge(:active)
      expect(badge).to include("bg-green-100")
      expect(badge).to include("text-green-800")
      expect(badge).to include("Active")
    end

    it "returns a badge with correct classes for past_due status" do
      badge = helper.render_subscription_badge(:past_due)
      expect(badge).to include("bg-amber-100")
      expect(badge).to include("text-amber-800")
      expect(badge).to include("Past Due")
    end

    it "returns a badge with correct classes for canceled status" do
      badge = helper.render_subscription_badge(:canceled)
      expect(badge).to include("bg-red-100")
      expect(badge).to include("text-red-800")
      expect(badge).to include("Canceled")
    end

    it "returns a badge with correct classes for paused status" do
      badge = helper.render_subscription_badge(:paused)
      expect(badge).to include("bg-slate-100")
      expect(badge).to include("text-slate-800")
      expect(badge).to include("Paused")
    end

    it "returns a default badge for unknown status" do
      badge = helper.render_subscription_badge(:unknown)
      expect(badge).to include("bg-slate-100")
      expect(badge).to include("text-slate-800")
      expect(badge).to include("Unknown")
    end

    it "handles string status" do
      badge = helper.render_subscription_badge("active")
      expect(badge).to include("bg-green-100")
      expect(badge).to include("Active")
    end

    it "includes appropriate span structure" do
      badge = helper.render_subscription_badge(:active)
      expect(badge).to include("<span")
      expect(badge).to include("inline-flex")
      expect(badge).to include("rounded-full")
    end
  end
end
