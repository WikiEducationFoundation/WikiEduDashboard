# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/analytics/retention_fetch_error"
require_dependency "#{Rails.root}/lib/analytics/retention_participant_history"

# Computes the per-student retention metrics for a course (currently the
# Scholars & Scientists / FellowsCohort program). RetentionPredictorsCsvBuilder
# turns them into the on-demand CSV; UpdateCourseRetentionStats stores them as
# RetentionStat rows for the report card.
#
# Metrics (edits an hour or more apart count as distinct "sessions"; edits
# closer together are lumped into one session):
#
#   1. Editing sessions during the course (course.start..course.end).
#   2. Days from course end to the student's first independent edit in the 30
#      days after the course. Capped/defaulted to 30 when they do not return
#      (smaller is better).
#   3. Editing sessions in the 30 days after the course ends.
#   4. Edits in the 30-day window that begins 60 days after the course ends
#      (course.end+60..course.end+90); a "survivor" made at least 5 such edits.
#
# Every participant is additionally classified by RetentionParticipantHistory as
# a long-term Wikipedian (500+ edits before the course), a returning participant
# (had already taken an earlier course), or neither. Consumers decide what to do
# with that; see RetentionSummaryBlock and RetentionMetrics.
#
# Metrics are computed on each student's combined cross-wiki edit timeline, from
# the live MediaWiki usercontribs API (all namespaces), which is why they have
# no dependency on stored revision data.
#
# A metric's window can only be read once real-world time has passed the window
# plus a one-day buffer: metrics 2 and 3 fill in 31 days after the course ends,
# metric 4 fills in 91 days after. Until then they are nil, so every reported
# value is final.
#
# A usercontribs request that fails after WikiApi's retries raises
# RetentionFetchError rather than being read as "no edits".
class RetentionStudentStats
  SESSION_GAP = 1.hour
  RETURN_WINDOW_DAYS = 30
  SURVIVAL_START_DAY = 60
  SURVIVAL_END_DAY = 90
  REPORTING_BUFFER_DAYS = 1

  # Days after course end at which each successive metric becomes final:
  # during-course sessions, then the return window, then the survival window.
  CHECKPOINT_DAYS = [
    REPORTING_BUFFER_DAYS,
    RETURN_WINDOW_DAYS + REPORTING_BUFFER_DAYS,
    SURVIVAL_END_DAY + REPORTING_BUFFER_DAYS
  ].freeze
  FINAL_STAGE = CHECKPOINT_DAYS.size

  # How many checkpoints the course has passed as of `at`: 0 while nothing is
  # final yet, FINAL_STAGE once every metric is. Nothing changes after that.
  def self.stage(course, at = Time.zone.now)
    CHECKPOINT_DAYS.count { |days| at >= course.end + days.days }
  end

  attr_reader :stats

  def initialize(course, now: Time.zone.now)
    @course = course
    @wikis = course.wikis.to_a
    @students = course.students.to_a.sort_by(&:username)
    @now = now
    @stats = @students.map { |student| student_stats(student) }
  end

  private

  def student_stats(student)
    times = combined_edit_times(student.username).sort
    history = RetentionParticipantHistory.new(@course, student, @wikis)
    { user_id: student.id }.merge(edit_metrics(student.username, times), history_columns(history))
  end

  def edit_metrics(username, times)
    {
      username:,
      sessions_during: count_sessions(times.select { |t| t <= @course.end }),
      days_to_return: days_to_return(times),
      sessions_after: sessions_after(times),
      edits_60_90: edits_in_survival_window(times)
    }
  end

  def history_columns(history)
    {
      prior_edit_count: history.prior_edit_count,
      prior_edits: history.prior_edit_count_label,
      long_term: history.long_term_wikipedian?,
      returning: history.returning?,
      prior_courses: history.prior_courses.size,
      prior_course_slugs: history.prior_course_slugs
    }
  end

  # Days from course end to the first edit in the 30-day return window, floored
  # to whole days. Defaults to the window length (30) when the student does not
  # return. Blank (nil) until the window has closed.
  def days_to_return(times)
    return nil unless return_window_available?
    first = return_window(times).min
    return RETURN_WINDOW_DAYS if first.nil?
    ((first - @course.end) / 1.day.to_i).floor
  end

  def sessions_after(times)
    return nil unless return_window_available?
    count_sessions(return_window(times))
  end

  def edits_in_survival_window(times)
    return nil unless survival_window_available?
    window = survival_window
    times.count { |t| window.cover?(t) }
  end

  # Edits strictly after the course end, through the RETURN_WINDOW_DAYS cutoff.
  def return_window(times)
    cutoff = @course.end + RETURN_WINDOW_DAYS.days
    times.select { |t| t > @course.end && t <= cutoff }
  end

  def survival_window
    (@course.end + SURVIVAL_START_DAY.days)..(@course.end + SURVIVAL_END_DAY.days)
  end

  def return_window_available?
    @now >= @course.end + CHECKPOINT_DAYS[1].days
  end

  def survival_window_available?
    @now >= @course.end + CHECKPOINT_DAYS[2].days
  end

  # Number of distinct editing sessions: a new session starts whenever the gap
  # since the previous edit is at least SESSION_GAP.
  def count_sessions(times)
    return 0 if times.empty?
    sessions = 1
    times.sort.each_cons(2) { |earlier, later| sessions += 1 if later - earlier >= SESSION_GAP }
    sessions
  end

  # A student's edit timestamps across every tracked wiki, merged into one
  # timeline (sessions and returns count regardless of which wiki they land on).
  def combined_edit_times(username)
    @wikis.flat_map { |wiki| edit_times(username, wiki) }
  end

  # All of a user's edit timestamps on a wiki from the course start through the
  # end of the survival window, fetched from the usercontribs API and paginated
  # until exhausted. WikiApi#query returns nil once its retries are exhausted;
  # that is a failed fetch (of any page), not an empty timeline.
  def edit_times(username, wiki)
    api = WikiApi.new(wiki)
    times = []
    continue = {}
    loop do
      response = api.query(usercontribs_query(username).merge(continue))
      raise RetentionFetchError.new(username, wiki) unless response
      contribs = response.data['usercontribs'] || []
      times.concat(contribs.map { |c| Time.zone.parse(c['timestamp']) })
      continue = response['continue']
      break unless continue
    end
    times
  end

  # Nothing after the survival window is ever used, so the fetch stops there
  # rather than at the present. That keeps a years-old course from walking every
  # edit its students have made since.
  def timeline_end
    [@course.end + SURVIVAL_END_DAY.days, @now].min
  end

  def usercontribs_query(username)
    {
      list: 'usercontribs',
      ucuser: username,
      ucstart: timeline_end.strftime('%Y%m%d%H%M%S'),
      ucend: @course.start.strftime('%Y%m%d%H%M%S'),
      ucprop: 'timestamp',
      uclimit: 'max'
    }
  end
end
