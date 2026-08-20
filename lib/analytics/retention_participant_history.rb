# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

# What a participant had already done before the course being reported on began:
# how much they had edited, and whether they had already taken an earlier course.
#
# RetentionPredictorsCsvBuilder uses both to decide which participants belong in
# which summary column. Long-term Wikipedians are listed in the report but left
# out of every aggregate; returning participants are aggregated separately from
# first-time ones, so a repeat participant's second-course numbers don't get read
# as a first-course outcome.
class RetentionParticipantHistory
  # At or above this many edits before the course started, a participant is
  # treated as an established Wikipedian rather than a retention subject.
  LONG_TERM_EDIT_THRESHOLD = 500

  attr_reader :prior_edit_count, :prior_courses

  def initialize(course, user, wikis)
    @course = course
    @user = user
    @wikis = wikis
    @prior_courses = find_prior_courses
    @prior_edit_count = count_prior_edits
  end

  def long_term_wikipedian?
    @prior_edit_count >= LONG_TERM_EDIT_THRESHOLD
  end

  def returning?
    @prior_courses.any?
  end

  # Exact below the threshold; "500+" once counting stopped at it.
  def prior_edit_count_label
    long_term_wikipedian? ? "#{LONG_TERM_EDIT_THRESHOLD}+" : @prior_edit_count.to_s
  end

  # Blank rather than an empty string, so a first-course participant's cell is
  # genuinely empty in the CSV.
  def prior_course_slugs
    @prior_courses.map(&:slug).join('; ').presence
  end

  private

  # Courses this user took as a student that started before this one did.
  # Courses that merely overlap this one do not count as prior.
  def find_prior_courses
    Course.joins(:courses_users)
          .where(courses_users: { user_id: @user.id,
                                  role: CoursesUsers::Roles::STUDENT_ROLE })
          .where('courses.start < ?', @course.start)
          .order(:start)
          .to_a
  end

  # Edits before the course start across every tracked wiki, summed. Counting
  # stops at the threshold: an editor with 50,000 prior edits costs no more API
  # calls than one with exactly 500.
  def count_prior_edits
    count = 0
    @wikis.each do |wiki|
      count += prior_edits_on(wiki, LONG_TERM_EDIT_THRESHOLD - count)
      break if count >= LONG_TERM_EDIT_THRESHOLD
    end
    count
  end

  # Edits on one wiki before the course start, paginated until `limit` of them
  # have been counted (or the user's contributions run out).
  def prior_edits_on(wiki, limit)
    api = WikiApi.new(wiki)
    count = 0
    continue = {}
    loop do
      response = api.query(prior_contribs_query.merge(continue))
      break unless response
      count += (response.data['usercontribs'] || []).count
      break if count >= limit
      continue = response['continue']
      break unless continue
    end
    [count, limit].min
  end

  # usercontribs defaults to listing backwards from ucstart, so this walks from
  # the moment before the course began into the past. The one-second offset keeps
  # an edit made exactly at the course start out of the "before" count, since the
  # report's during-course window already includes it.
  def prior_contribs_query
    {
      list: 'usercontribs',
      ucuser: @user.username,
      ucstart: (@course.start - 1.second).strftime('%Y%m%d%H%M%S'),
      ucprop: 'timestamp',
      uclimit: 'max'
    }
  end
end
