# frozen_string_literal: true

module UpdateServiceErrorLogging
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end

  def error_count
    @error_count ||= 0
  end

  def update_error_stats
    @error_count = error_count + 1
  end

  def sentry_tags
    { update_service_id: sentry_tag_uuid, course: @course.slug }
  end
end
