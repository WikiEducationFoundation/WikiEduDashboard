# frozen_string_literal: true

module ApiErrorHandling
  def log_error(error, update_service: nil, sentry_extra: nil, sentry_tags: nil)
    Rails.logger.info "Caught #{error}"
    base_tags = nil
    if update_service.present?
      new_errors_count = sentry_extra&.dig(:new_errors_count) || 1
      update_service.update_error_stats(new_errors_count)
      base_tags = update_service.sentry_tags
    end
    merged_tags = merge_sentry_tags(base_tags, sentry_tags)
    Sentry.capture_exception(error,
                             level: error_level(error),
                             extra: sentry_extra,
                             tags: merged_tags)
    return nil
  end

  def merge_sentry_tags(base_tags, extra_tags)
    return base_tags if extra_tags.blank?
    (base_tags || {}).merge(extra_tags)
  end

  def error_level(error)
    self.class.const_get(:TYPICAL_ERRORS).include?(error.class) ? 'warning' : 'error'
  end
end
