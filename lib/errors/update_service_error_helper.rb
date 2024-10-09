# frozen_string_literal: true

module UpdateServiceErrorHelper
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end

  def error_count
    @error_count ||= 0
  end

  def new_errors
    @new_errors_count ||= 0
  end

  def new_errors_count=(value)
    @new_errors_count = value
  end

  def update_error_stats
    @error_count = error_count + new_errors
  end

  def sentry_tags
    { update_service_id: sentry_tag_uuid, course: @course.slug }
  end
end
