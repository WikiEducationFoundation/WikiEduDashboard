# frozen_string_literal: true

module CourseUpdateHelper
  def generate_sentry_tag_uuid
    SecureRandom.uuid
  end
end
