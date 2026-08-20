# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

#= RetainedEditorCheckWorker
# Enqueued daily by DailyUpdate.
# Checks new editors whose courses ended >= 30 days ago and whose
# post-course retention has not yet been recorded.
# Queries the MediaWiki usercontribs API in batches of 40 users to check
# for mainspace contributions made after (course.end + 7 days).
# Records retained_after_course (boolean) and retained_after_course_checked_at
# on the courses_users record permanently.
class RetainedEditorCheckWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'daily_update', lock: :until_executed

  DAYS_AFTER_END = 7
  OBSERVATION_DAYS = 30
  BATCH_SIZE = 40

  def perform
    Rails.logger.info { 'RetainedEditorCheckWorker: starting check for eligible new editors' }
    total_checked = 0

    eligible_course_ids.each do |course_id|
      course = Course.find_by(id: course_id)
      next unless course

      total_checked += check_course_new_editors(course)
    end

    Rails.logger.info { "RetainedEditorCheckWorker: finished check, processed #{total_checked} records" }
    total_checked
  end

  def check_course_new_editors(course)
    candidates = eligible_candidates_for_course(course)
    return 0 if candidates.empty?

    wiki = course.home_wiki
    threshold = course.end + DAYS_AFTER_END.days
    checked_count = 0

    candidates.in_groups_of(BATCH_SIZE, false) do |batch|
      checked_count += process_batch(batch, wiki, threshold)
    end

    checked_count
  end

  private

  def eligible_course_ids
    CoursesUsers
      .joins(:course, :user)
      .where(role: CoursesUsers::Roles::STUDENT_ROLE, retained_after_course: nil)
      .where('courses.end <= ?', OBSERVATION_DAYS.days.ago)
      .where(courses: { private: false })
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .distinct
      .pluck(:course_id)
  end

  def eligible_candidates_for_course(course)
    CoursesUsers
      .joins(:user)
      .where(
        course_id: course.id,
        role: CoursesUsers::Roles::STUDENT_ROLE,
        retained_after_course: nil
      )
      .where('users.registered_at >= ? AND users.registered_at <= ?', course.start, course.end)
      .select('courses_users.id, courses_users.user_id, users.username')
  end

  def process_batch(batch, wiki, threshold)
    usernames = batch.map(&:username)
    active_usernames = fetch_active_usernames(usernames, wiki, threshold)
    return 0 if active_usernames.nil?

    now = Time.zone.now
    batch.each do |cu|
      retained = active_usernames.include?(cu.username)
      CoursesUsers.where(id: cu.id).update_all(
        retained_after_course: retained,
        retained_after_course_checked_at: now,
        updated_at: now
      )
    end

    batch.size
  end

  def fetch_active_usernames(usernames, wiki, threshold)
    active_usernames = Set.new
    target_users = usernames.to_set
    continue_param = nil

    loop do
      query = {
        list: 'usercontribs',
        ucuser: usernames,
        ucnamespace: 0, # mainspace only
        ucstart: threshold.strftime('%Y%m%d%H%M%S'),
        uclimit: 500,
        ucprop: '',
        ucdir: 'newer'
      }
      query.merge!(continue_param) if continue_param

      response = WikiApi.new(wiki).query(query)
      return nil unless response&.data&.key?('usercontribs')

      contribs = response.data['usercontribs'] || []
      contribs.each do |c|
        active_usernames.add(c['user']) if c['user']
      end

      # Stop early if all batch users have been confirmed active
      break if active_usernames.superset?(target_users)

      continue_param = response.data['continue']
      break if continue_param.nil? || contribs.empty?
    end

    active_usernames.to_a
  end
end
