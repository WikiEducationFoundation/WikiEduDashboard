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

    Rails.logger.info do
      "RetainedEditorCheckWorker: finished, processed #{total_checked} records"
    end
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

  def self.eligible_course_ids
    CoursesUsers
      .joins(:course, :user)
      .where(role: CoursesUsers::Roles::STUDENT_ROLE, retained_after_course: nil)
      .where('courses.end <= ?', OBSERVATION_DAYS.days.ago)
      .where(courses: { private: false })
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .distinct
      .pluck(:course_id)
  end

  private

  def eligible_course_ids
    self.class.eligible_course_ids
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
    retained_ids, not_retained_ids = batch.partition { |cu| active_usernames.include?(cu.username) }
                                          .map { |group| group.map(&:id) }

    if retained_ids.any?
      CoursesUsers.where(id: retained_ids).update_all(
        retained_after_course: true,
        retained_after_course_checked_at: now,
        updated_at: now
      )
    end

    if not_retained_ids.any?
      CoursesUsers.where(id: not_retained_ids).update_all(
        retained_after_course: false,
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
      result = query_usercontribs(usernames, wiki, threshold, continue_param)
      return nil unless result

      result[:users].each { |u| active_usernames.add(u) }
      break if active_usernames.superset?(target_users)

      continue_param = result[:continue]
      break if continue_param.nil?
    end

    active_usernames.to_a
  end

  def query_usercontribs(usernames, wiki, threshold, continue_param)
    query = usercontribs_query(usernames, threshold)
    query.merge!(continue_param) if continue_param

    response = WikiApi.new(wiki).query(query)
    return nil unless response&.data&.key?('usercontribs')

    contribs = response.data['usercontribs'] || []
    {
      users: contribs.filter_map { |c| c['user'] },
      continue: contribs.empty? ? nil : response.data['continue']
    }
  end

  def usercontribs_query(usernames, threshold)
    {
      list: 'usercontribs',
      ucuser: usernames,
      ucnamespace: 0,
      ucstart: threshold.strftime('%Y%m%d%H%M%S'),
      uclimit: 500,
      ucprop: '',
      ucdir: 'newer'
    }
  end
end
