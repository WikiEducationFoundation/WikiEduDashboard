# frozen_string_literal: true

# Validates input filters for system-wide CSV exports before job processing.
class SystemCsvFilterValidator
  VALID_COURSE_TYPES = %w[
    ClassroomProgramCourse Editathon BasicCourse FellowsCohort
    ArticleScopedProgram VisitingScholarship LegacyCourse SingleUser
  ].freeze
  VALID_STATUSES = %w[active archived].freeze

  def initialize(filters)
    @filters = filters
  end

  def errors
    errs = []
    validate_course_type(errs)
    validate_status(errs)
    validate_dates(errs)
    validate_campaign_slug(errs)
    errs
  end

  private

  def validate_course_type(errs)
    return unless @filters[:course_type].present?
    return if VALID_COURSE_TYPES.include?(@filters[:course_type])
    errs << "Invalid course_type: #{@filters[:course_type]}"
  end

  def validate_status(errs)
    return unless @filters[:status].present?
    return if VALID_STATUSES.include?(@filters[:status])
    errs << "Invalid status: #{@filters[:status]}"
  end

  def validate_dates(errs)
    %i[start_date end_date].each do |key|
      next unless @filters[key].present?
      Date.parse(@filters[key])
    rescue Date::Error
      errs << "Invalid #{key}: #{@filters[key]}"
    end
  end

  def validate_campaign_slug(errs)
    return unless @filters[:campaign_slug].present?
    return if Campaign.exists?(slug: @filters[:campaign_slug])
    errs << "Campaign not found: #{@filters[:campaign_slug]}"
  end
end
