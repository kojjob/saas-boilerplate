# frozen_string_literal: true

# Configure Audited gem for activity logging

# Configure ActiveRecord to allow serialization of ActiveSupport::TimeWithZone
# This is needed for Rails 7+ with Psych 4+
Rails.application.config.active_record.yaml_column_permitted_classes = [
  ActiveSupport::TimeWithZone,
  ActiveSupport::TimeZone,
  Time,
  Date,
  DateTime,
  BigDecimal,
  Symbol
]

# Optional: Configure audited to use JSON serialization instead of YAML
# This avoids the Psych::DisallowedClass issue entirely
Audited.config do |config|
  # Serialize audit changes as JSON instead of YAML (more compatible)
  config.audit_class = Audited::Audit
end
