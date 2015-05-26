require "#{Rails.root}/lib/wiki"
require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/lib/importers/cohort_importer"

#= Imports and updates courses from Wikipedia into the dashboard database
class CourseImporter
  ################
  # Entry points #
  ################
  def self.get_course_info(course_id)
    Wiki.get_course_info course_id
  end

  ##############
  # API Access #
  ##############
  def self.update_all_courses(initial=false, raw_ids={})
    raw_ids = Wiki.course_list if raw_ids.empty?
    listed_ids = raw_ids.values.flatten
    course_ids = listed_ids | Course.where(listed: true).pluck(:id)

    if initial
      _minimum = course_ids.min
      maximum = course_ids.max
      course_ids = (1..maximum).to_a
    end

    # Break up course_ids into smaller groups that Wikipedia's API can handle.
    data = Utils.chunk_requests(course_ids) { |c| get_course_info c }
    import_courses(raw_ids, data)
  end

  ###########
  # Helpers #
  ###########
  def self.import_courses(raw_ids, data)
    # Encountered an API error; cancel course import for today
    if data.include? nil
      Rails.logger.warn 'Network error. Course import cancelled.'
      return
    end

    courses = []
    participants = {}
    listed_ids = raw_ids.values.flatten
    valid_ids = data.map { |c| c['course']['id'] }
    deleted_ids = listed_ids - valid_ids

    # Delist courses that have been deleted
    deleted_ids.each do |id|
      Course.find(id).delist if Course.exists?(id)
    end

    # Update courses from new data
    data.each do |c|
      c['course']['listed'] = listed_ids.include?(c['course']['id'])
      course = Course.new(id: c['course']['id'])
      course.update(c, false)
      courses.push course
      participants[c['course']['id']] = c['participants']
    end
    Course.import courses, on_duplicate_key_update: [:start, :end, :listed]

    # Update cohort membership
    CohortImporter.update_cohorts raw_ids

    import_users participants
    import_assignments participants
  end

  def self.import_users(participants)
    users = []
    participants.each do |_course_id, groups|
      groups.each_with_index do |(r, _p), i|
        users = UserImporter.add_users(groups[r], i, nil, false) | users
      end
    end
    User.import users
  end

  def self.import_assignments(participants)
    assignments = []
    raw_assignments = []
    ActiveRecord::Base.transaction do
      participants.each do |course_id, group|
        group_flat = group.map do |role, users|
          users = [users] unless users.instance_of? Array
          users.empty? ? nil : users.each { |u| u.merge! 'role' => role }
        end
        group_flat = group_flat.compact.flatten.sort_by { |user| user['id'] }
        group_flat = update_enrollment course_id, group_flat
        all_assignments = update_assignments course_id, group_flat
        assignments += all_assignments[:assignments]
        raw_assignments += all_assignments[:raw_assignments]
      end
    end
    Assignment.import assignments

    # Update reviewers
    raw_assignments.each do |raw_assignment|
      raw_title = raw_assignment['title']
      assignment_id = Assignment.find_by(article_title: raw_title).id
      raw_assignment.each do |_key, reviewer|
        next unless reviewer.is_a?(Hash) && reviewer.key?('username')
        AssignmentsUsers.new(
          user_id: reviewer['id'],
          assignment_id: assignment_id
        ).save
      end
    end
  end

  def self.update_enrollment(course_id, group_flat)
    # Update enrollment (add/remove students)
    user_ids = group_flat.map { |user| user['id'] }
    course = Course.find_by(id: course_id)
    return [] if user_ids.empty?

    role_index = %w(student instructor online_volunteer
                    campus_volunteer wiki_ed_staff)

    # Set up structures for operating on
    existing_flat = course.courses_users.map do |cu|
      { 'id' => cu.user_id, 'role' => role_index[cu.role] }
    end
    new_flat = group_flat.map do |u|
      role = u['username'].include?('(Wiki Ed)') ? role_index[4] : u['role']
      { 'id' => u['id'], 'role' => role }
    end

    # Unenroll users who have been removed
    unless course.users.empty?
      unenrolled = (existing_flat - new_flat).map { |u| u['id'] }
      course.users.delete(course.users.find(unenrolled))
    end

    # Enroll new users
    enrolled = (new_flat - existing_flat).map { |u| u['id'] }
    return group_flat unless enrolled.count > 0
    enroll_users(group_flat, enrolled, course)
  end

  def self.enroll_users(users, enrolled, course)
    role_index = %w(student instructor online_volunteer
                    campus_volunteer wiki_ed_staff)
    users.each do |u|
      next() unless enrolled.include? u['id']
      role = role_index.index(u['role'])
      role = 4 if u['username'].include? '(Wiki Ed)'
      CoursesUsers.new(user_id: u['id'], course: course, role: role).save
    end
  end

  def self.update_assignments(course_id, group_flat)
    # Add assigned articles
    assignments = []
    raw_assignments = []
    group_flat.each do |user|
      # Each assigned article has a numerical (string) index, starting from 0.
      next unless user.key? '0'

      # Each user has username, id, & role. Extra keys are assigned articles.
      assignment_count = user.keys.count - 3

      (0...assignment_count).each do |a|
        raw_assignment = user[a.to_s]
        raw_assignments.push raw_assignment
        assignment_title = raw_assignment['title']
        assignment = {
          'user_id' => user['id'],
          'course_id' => course_id,
          'article_title' => assignment_title,
          'article_id' => nil
        }
        article = Article.find_by(title: assignment_title)
        assignment['article_id'] = article.nil? ? nil : article.id
        new_assignment = Assignment.new(assignment)
        assignments.push new_assignment
      end
    end
    return { assignments: assignments, raw_assignments: raw_assignments }
  end
end
