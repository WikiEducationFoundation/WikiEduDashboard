# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/analytics/retention_participant_history"
require_dependency "#{Rails.root}/lib/analytics/retention_summary_block"
require 'csv'

# Builds the "Retention predictors" CSV report for a course (currently the
# Scholars & Scientists / FellowsCohort program).
#
# The report combines a per-course summary block with a per-student detail
# block in a single CSV. Metrics (edits an hour or more apart count as distinct
# "sessions"; edits closer together are lumped into one session):
#
#   1. Editing sessions during the course (course.start..course.end).
#   2. Days from course end to the student's first independent edit in the 30
#      days after the course. Capped/defaulted to 30 when they do not return
#      (smaller is better).
#   3. Editing sessions in the 30 days after the course ends.
#   4. Edits in the 30-day window that begins 60 days after the course ends
#      (course.end+60..course.end+90); a "survivor" made at least 5 such edits.
#
# The summary block also reports two aggregate conveniences derived from the
# per-student metrics above: the count of participants with zero editing sessions
# during the course, and the count of participants who edited in the 30 days
# after it ended.
#
# Every participant is additionally classified by RetentionParticipantHistory as
# a long-term Wikipedian (1000+ edits before the course), a returning participant
# (had already taken an earlier course), or neither. That classification decides
# how the summary block aggregates them; see RetentionSummaryBlock. The detail
# block reports all three groups alike, so an excluded participant is still
# visible as somebody who took part.
#
# Metrics are computed on each student's combined cross-wiki edit timeline, from
# the live MediaWiki usercontribs API (all namespaces), which is why the report
# has no dependency on stored revision data.
#
# A metric's window can only be read once real-world time has passed the window
# plus a one-day buffer: metrics 2 and 3 fill in 31 days after the course ends,
# metric 4 fills in 91 days after. Cells (and the summary aggregates that depend
# on them) are left blank until then, so every reported value is final.
class RetentionPredictorsCsvBuilder
  SESSION_GAP = 1.hour
  RETURN_WINDOW_DAYS = 30
  SURVIVAL_START_DAY = 60
  SURVIVAL_END_DAY = 90
  REPORTING_BUFFER_DAYS = 1

  def initialize(course)
    @course = course
    @wikis = course.wikis.to_a
    @students = course.students.to_a.sort_by(&:username)
    @now = Time.zone.now
  end

  def generate_csv
    stats = @students.map { |student| student_stats(student) }
    CSV.generate do |csv|
      RetentionSummaryBlock.new(stats).rows.each { |row| csv << row }
      csv << []
      detail_rows(stats).each { |row| csv << row }
    end
  end

  private

  DETAIL_HEADERS = ['username', 'sessions during course', 'days to first independent edit',
                    'sessions in 30 days after course', 'edits in days 60-90',
                    'edits before course', 'long-term Wikipedian (1000+ edits)',
                    'prior courses', 'prior course slugs'].freeze

  def student_stats(student)
    times = combined_edit_times(student.username).sort
    history = RetentionParticipantHistory.new(@course, student, @wikis)
    edit_metrics(student.username, times).merge(history_columns(history))
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
      prior_edits: history.prior_edit_count_label,
      long_term: history.long_term_wikipedian?,
      returning: history.returning?,
      prior_courses: history.prior_courses.size,
      prior_course_slugs: history.prior_course_slugs
    }
  end

  def detail_rows(stats)
    rows = stats.map do |s|
      [s[:username], s[:sessions_during], s[:days_to_return], s[:sessions_after], s[:edits_60_90],
       s[:prior_edits], (s[:long_term] ? 'yes' : nil), s[:prior_courses], s[:prior_course_slugs]]
    end
    [['Per-student detail'], DETAIL_HEADERS, *rows]
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
    @now >= @course.end + (RETURN_WINDOW_DAYS + REPORTING_BUFFER_DAYS).days
  end

  def survival_window_available?
    @now >= @course.end + (SURVIVAL_END_DAY + REPORTING_BUFFER_DAYS).days
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

  # All of a user's edit timestamps on a wiki since the course start, fetched
  # from the usercontribs API and paginated until exhausted.
  def edit_times(username, wiki)
    api = WikiApi.new(wiki)
    times = []
    continue = {}
    loop do
      response = api.query(usercontribs_query(username).merge(continue))
      break unless response
      contribs = response.data['usercontribs'] || []
      times.concat(contribs.map { |c| Time.zone.parse(c['timestamp']) })
      continue = response['continue']
      break unless continue
    end
    times
  end

  def usercontribs_query(username)
    {
      list: 'usercontribs',
      ucuser: username,
      ucstart: Time.zone.now.strftime('%Y%m%d%H%M%S'),
      ucend: @course.start.strftime('%Y%m%d%H%M%S'),
      ucprop: 'timestamp',
      uclimit: 'max'
    }
  end
end
