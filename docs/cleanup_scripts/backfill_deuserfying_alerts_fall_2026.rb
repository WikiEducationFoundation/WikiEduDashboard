# frozen_string_literal: true
# This script creates the DeUserfyingAlerts that were missed after enwiki's
# edit filter 630 switched from the 'de-userfying' tag to
# 'new user move into mainspace' on 2026-07-03, for Fall 2026 courses.
#
# Recent changes only go back 30 days, so it reads the move log instead.
# Alerts are created through DeUserfyingEditAlertMonitor#create_alert, which
# skips alerts that already exist and emails the content expert for each new one.
#
# Run it first with dry_run = true to list the moves it would alert on.

require "#{Rails.root}/lib/alerts/de_userfying_edit_alert_monitor"

dry_run = true

wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
api = WikiApi.new(wiki)
monitor = DeUserfyingEditAlertMonitor.new
courses = Campaign.find_by(slug: 'fall_2026').courses.to_a
course_ids_by_user = CoursesUsers
                     .where(course_id: courses.map(&:id),
                            role: [CoursesUsers::Roles::STUDENT_ROLE,
                                   CoursesUsers::Roles::INSTRUCTOR_ROLE])
                     .joins(:user).pluck('users.username', :course_id)
                     .group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
courses_by_id = courses.index_by(&:id)

moves = []
params = { list: 'logevents', letype: 'move', letag: DeUserfyingEditAlertMonitor::TAG,
           leend: '2026-07-03T00:00:00Z', lelimit: 500,
           leprop: 'ids|title|user|timestamp|details' }
loop do
  response = api.query(params)
  moves += response.data['logevents'].select { |move| course_ids_by_user.key?(move['user']) }
  break unless response['continue']
  params = params.merge(response['continue'])
end
puts "Found #{moves.count} moves by Fall 2026 students and instructors"

created_count = 0
moves.reverse_each do |move|
  # Only alert courses that had started by the time of the move.
  course_ids = course_ids_by_user[move['user']].select do |course_id|
    courses_by_id[course_id].start <= Time.zone.parse(move['timestamp'])
  end
  puts [move['timestamp'], move['user'], move['title'],
        move.dig('params', 'target_title'), course_ids.join(',')].join("\t")
  next if dry_run || course_ids.empty?

  user = User.find_by(username: move['user'])
  # For moves, logpage is the moved page; pageid is the redirect left behind.
  article = monitor.article_by_mw_page_id(move['logpage'])
  course_ids.each do |course_id|
    next if monitor.alert_already_exists?(course_id, article&.id, move['revid'])
    details = { logid: move['logid'], timestamp: move['timestamp'], title: move['title'] }
    monitor.create_alert(user.id, course_id, article&.id, move['revid'], details)
    created_count += 1
  end
end
puts "Created #{created_count} DeUserfyingAlerts" unless dry_run
