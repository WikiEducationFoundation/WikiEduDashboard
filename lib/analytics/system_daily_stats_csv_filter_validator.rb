# frozen_string_literal: true

# Validates date filters for the daily system statistics CSV export.
# Follows the same pattern as SystemCsvFilterValidator.
class SystemDailyStatsCsvFilterValidator
  def initialize(filters)
    @filters = filters
  end

  def errors
    errs = validate_date_formats
    return errs if errs.any?
    validate_date_range(errs)
    errs
  end

  private

  def validate_date_formats
    %i[start_date end_date].filter_map do |key|
      next unless @filters[key].present?
      Date.parse(@filters[key])
      nil
    rescue Date::Error
      "Invalid #{key}: #{@filters[key]}"
    end
  end

  def validate_date_range(errs)
    return unless @filters[:start_date].present? && @filters[:end_date].present?
    return if Date.parse(@filters[:start_date]) <= Date.parse(@filters[:end_date])
    errs << 'start_date must be before end_date'
  end
end
