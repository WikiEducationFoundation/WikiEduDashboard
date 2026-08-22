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
  DEFAULT_PERFORM_LIMIT = 50

  def perform(limit = DEFAULT_PERFORM_LIMIT)
    Rails.logger.info { 'RetainedEditorCheckWorker: starting check for eligible new editors' }
    total_checked = 0

    eligible_course_ids(limit).each do |course_id|
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

  def self.eligible_course_ids(limit = nil)
    scope = CoursesUsers
      .joins(:course, :user)
      .where(role: CoursesUsers::Roles::STUDENT_ROLE, retained_after_course: nil)
      .where('courses.end <= ?', OBSERVATION_DAYS.days.ago)
      .where(courses: { private: false })
      .where(NewEditorDateConditions::DURING_PROGRAM)
      .distinct

    scope = scope.limit(limit) if limit
    scope.pluck(:course_id)
  end

  private

  def eligible_course_ids(limit = nil)
    self.class.eligible_course_ids(limit)
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

    update_batch_retention(batch, active_usernames)
    batch.size
  end

  def update_batch_retention(batch, active_usernames)
    now = Time.zone.now
    retained, not_retained = batch.partition { |cu| active_usernames.include?(cu.username) }

    bulk_update(retained.map(&:id), true, now) if retained.any?
    bulk_update(not_retained.map(&:id), false, now) if not_retained.any?
  end

  def bulk_update(ids, status, timestamp)
    CoursesUsers.where(id: ids).update_all(
      retained_after_course: status,
      retained_after_course_checked_at: timestamp,
      updated_at: timestamp
    )
  end

  def fetch_active_usernames(usernames, wiki, threshold)
    active_set = fetch_batch_active_usernames(usernames, wiki, threshold)
    return active_set if active_set

    # Fallback to per-user queries if batch query failed (e.g. invalid username error)
    fetch_individual_active_usernames(usernames, wiki, threshold)
  end

  def fetch_batch_active_usernames(usernames, wiki, threshold)
    active_usernames = Set.new
    target_users = usernames.to_set
    pending = usernames.dup
    continue_param = nil

    loop do
      result = query_usercontribs(pending, wiki, threshold, continue_param)
      return nil unless result

      result[:users].each { |u| active_usernames.add(u) }
      return active_usernames if active_usernames.superset?(target_users)

      pending, continue_param = next_pending_and_continue(
        target_users, active_usernames, pending, result
      )
      break if batch_complete?(pending, target_users, active_usernames, continue_param)
    end

    active_usernames
  end

  def batch_complete?(pending, target_users, active_usernames, continue_param)
    pending.nil? || (pending == (target_users - active_usernames).to_a && continue_param.nil?)
  end

  def next_pending_and_continue(target_users, active_usernames, pending, result)
    new_pending = (target_users - active_usernames).to_a
    return [nil, nil] if new_pending.empty?

    if new_pending.size < pending.size
      [new_pending, nil]
    else
      [pending, result[:continue]]
    end
  end

  def fetch_individual_active_usernames(usernames, wiki, threshold)
    active_usernames = Set.new
    usernames.each do |username|
      result = query_usercontribs([username], wiki, threshold, nil)
      active_usernames.add(username) if result && result[:users].any?
    end
    active_usernames
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
