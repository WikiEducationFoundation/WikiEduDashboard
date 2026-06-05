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

  def reference_counter_403_count
    @reference_counter_403_count ||= 0
  end

  def record_reference_counter_403(count = 1)
    @reference_counter_403_count = reference_counter_403_count + count
  end

  def too_many_requests_count
    @too_many_requests_count ||= 0
  end

  def record_too_many_requests(count = 1)
    @too_many_requests_count = too_many_requests_count + count
  end

  def sentry_tags
    { update_service_id: sentry_tag_uuid, course: @course.slug }
  end
end
