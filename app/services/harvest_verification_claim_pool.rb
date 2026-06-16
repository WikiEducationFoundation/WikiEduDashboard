# frozen_string_literal: true

# Populates the claim-verification pool by harvesting cited claims from
# past-term courses whose subject matches a currently-active course's subject,
# so the pool fills with material relevant to what students are studying now.
# Newest-ended matching courses are processed first; courses already
# represented in the pool are skipped, so each (scheduled) run makes forward
# progress to new source courses rather than re-fetching. Network-bound —
# bounded by COURSE_LIMIT source courses per run.
class HarvestVerificationClaimPool
  attr_reader :courses_harvested, :claims_collected

  DEFAULT_COURSE_LIMIT = 25

  def initialize(course_limit: DEFAULT_COURSE_LIMIT)
    @course_limit = course_limit
    @courses_harvested = 0
    @claims_collected = 0
    perform
  end

  private

  def perform
    source_courses.each do |course|
      @claims_collected += HarvestCourseClaims.new(course).claims.size
      @courses_harvested += 1
    end
  end

  def source_courses
    return Course.none if active_subjects.empty?

    Course.ended
          .where(subject: active_subjects)
          .where.not(id: already_harvested_course_ids)
          .order(end: :desc)
          .limit(@course_limit)
  end

  def active_subjects
    @active_subjects ||= Course.strictly_current.distinct.pluck(:subject).compact_blank
  end

  def already_harvested_course_ids
    VerificationClaim.distinct.pluck(:source_course_id).compact
  end
end
