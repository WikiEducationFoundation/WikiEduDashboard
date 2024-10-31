# frozen_string_literal: true

module UpdateServiceErrorHelper
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end

  def error_count
    @error_count ||= 0
  end

  def update_error_stats(new_errors_count = 1)
    @error_count = error_count + new_errors_count
  end

  def sentry_tags
    { update_service_id: sentry_tag_uuid, course: @course.slug }
  end
end
