# frozen_string_literal: true

module CourseUpdateHelper
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end
end
