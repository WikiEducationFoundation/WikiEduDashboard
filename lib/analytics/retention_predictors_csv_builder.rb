# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require 'csv'

# Builds the "Retention predictors" CSV report for a course (currently the
# Scholars & Scientists / FellowsCohort program).
#
# v1 has a single metric: the number of distinct editing sessions per student.
# Edits an hour or more apart count as distinct sessions; edits closer together
# are lumped into one session. Sessions are counted per tracked wiki and across
# all tracked wikis combined, in two independent windows: during the course
# (course.start..course.end) and after it ended (course.end..now).
#
# Edit timestamps come straight from the live MediaWiki usercontribs API, across
# all namespaces, so this report has no dependency on stored revision data.
class RetentionPredictorsCsvBuilder
  SESSION_GAP = 1.hour

  def initialize(course)
    @course = course
    @wikis = course.wikis.to_a
    @students = course.students.to_a.sort_by(&:username)
  end

  def generate_csv
    CSV.generate do |csv|
      csv << headers
      @students.each { |student| csv << row(student) }
    end
  end

  private

  def headers
    wiki_headers = @wikis.flat_map do |wiki|
      ["#{wiki.domain} sessions (during course)", "#{wiki.domain} sessions (after course)"]
    end
    ['username', *wiki_headers,
     'all wikis sessions (during course)', 'all wikis sessions (after course)']
  end

  def row(student)
    during_all = []
    after_all = []
    wiki_cells = @wikis.flat_map do |wiki|
      during, after = edit_times(student.username, wiki).partition { |t| t <= @course.end }
      during_all.concat(during)
      after_all.concat(after)
      [count_sessions(during), count_sessions(after)]
    end
    [student.username, *wiki_cells, count_sessions(during_all), count_sessions(after_all)]
  end

  # Number of distinct editing sessions: a new session starts whenever the gap
  # since the previous edit is at least SESSION_GAP.
  def count_sessions(times)
    return 0 if times.empty?
    sessions = 1
    times.sort.each_cons(2) { |earlier, later| sessions += 1 if later - earlier >= SESSION_GAP }
    sessions
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
