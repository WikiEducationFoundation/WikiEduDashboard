require "#{Rails.root}/lib/wiki"
require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/lib/importers/cohort_importer"

#= Imports and updates courses from Wikipedia into the dashboard database
class CourseImporter
  ################
  # Entry points #
  ################
  def self.update_all_courses(initial=false, raw_ids={})
    raw_ids = Wiki.course_list if raw_ids.empty?
    listed_ids = raw_ids.values.flatten
    course_ids = listed_ids | Course.legacy.where(listed: true).pluck(:id)

    if initial
      _minimum = course_ids.min
      maximum = course_ids.max
      course_ids = (1..maximum).to_a
    end

    # Break up course_ids into smaller groups that Wikipedia's API can handle.
    data = Utils.chunk_requests(course_ids) { |c| get_course_info c }
    import_courses(raw_ids, data)
  end

  ##############
  # API Access #
  ##############

  def self.get_course_info(course_id)
    WikiLegacyCourses.get_course_info course_id
  end

  def self.import_courses(raw_ids, data)
    # Encountered an API error; cancel course import for today
    return unless data_ok?(data)

    courses = []
    participants = {}
    listed_ids = raw_ids.values.flatten

    # Delist courses that have been deleted
    handle_deleted_courses(listed_ids, course_data)

    # Update courses from new data
    data.each do |c|
      id = c['course']['id']
      c['course']['listed'] = listed_ids.include?(id)
      course = Course.new(id: id)
      course.update(c, false)
      courses.push course
      participants[id] = c['participants']
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
        # Students
        users = UserImporter.add_users(groups[r], i, nil, false) | users
        # Assignment reviewers
        reviewers = reviewers(groups[r])
        users = UserImporter.add_users(reviewers, nil, nil, false) | users
      end
    end
    User.import users
  end

  def self.reviewers(group)
    reviewers = []
    group.each do |user|
      # Add reviewers
      a_index = r_index = 0
      while user.key? a_index.to_s
        while user[a_index.to_s].key? r_index.to_s
          reviewers.push(
            'username' => user[a_index.to_s][r_index.to_s]['username'],
            'id' => user[a_index.to_s][r_index.to_s]['id']
          )
          r_index += 1
        end
        a_index += 1
      end
    end
    reviewers
  end

  def self.import_assignments(participants)
    assignments = []
    ActiveRecord::Base.transaction do
      participants.each do |course_id, group|
        assignments += get_assignments_for_group(course_id, group)
      end
    end
    Assignment.import assignments
  end

  def self.get_assignments_for_group(course_id, group)
    group_flat = group.map do |role, users|
      users = [users] unless users.instance_of? Array
      users.empty? ? nil : users.each { |u| u.merge! 'role' => role }
    end
    group_flat = group_flat.compact.flatten.sort_by { |user| user['id'] }
    group_flat = update_enrollment course_id, group_flat
    all_assignments = update_assignments course_id, group_flat
    all_assignments
  end

  def self.update_enrollment(course_id, group_flat)
    # Update enrollment (add/remove students)
    user_ids = group_flat.map { |user| user['id'] }
    return [] if user_ids.empty?

    course = Course.find_by(id: course_id)

    # Set up structures for operating on
    existing_flat = existing_enrollment_flat(course)
    new_flat = new_enrollment_flat(group_flat)

    # Unenroll users who have been removed
    unenroll_removed_users(course, existing_flat, new_flat)

    # Enroll new users
    enrolled = (new_flat - existing_flat).map { |u| u['id'] }
    return group_flat unless enrolled.count > 0
    enroll_users(group_flat, enrolled, course)
  end

  def self.existing_enrollment_flat(course)
    course.courses_users.map do |cu|
      { 'id' => cu.user_id, 'role' => role_index[cu.role] }
    end
  end

  def self.new_enrollment_flat(group_flat)
    group_flat.map do |u|
      role = u['username'].include?('(Wiki Ed)') ? role_index[4] : u['role']
      { 'id' => u['id'], 'role' => role }
    end
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
    group_flat.each do |user|
      # Each assigned article has a numerical (string) index, starting from 0.
      next unless user.key? '0'

      # Each user has username, id, & role. Extra keys are assigned articles.
      assignment_count = user.keys.count - 3

      (0...assignment_count).each do |a|
        raw = user[a.to_s]
        article = Article.find_by(title: raw['title'])
        # role 0 is for assignee
        assignment = assignment_hash(user, course_id, raw, article, 0)
        new_assignment = Assignment.new(assignment)
        assignments.push new_assignment

        # Get the reviewers
        raw.each do |_key, reviewer|
          next unless reviewer.is_a?(Hash) && reviewer.key?('username')
          # role 1 is for reviewer
          assignment = assignment_hash(reviewer, course_id, raw, article, 1)

          new_assignment = Assignment.new(assignment)
          assignments.push new_assignment
        end
      end
    end
    return assignments
  end

  #######################
  # Database operations #
  #######################
  def self.handle_deleted_courses(listed_ids, course_data)
    valid_ids = course_data.map { |c| c['course']['id'] }
    deleted_ids = listed_ids - valid_ids
    deleted_ids.each do |id|
      Course.find(id).delist if Course.exists?(id)
    end
  end

  def self.unenroll_removed_users(course, existing_flat, new_flat)
    unless course.users.empty?
      unenrolled = (existing_flat - new_flat).map { |u| u['id'] }
      course.users.delete(course.users.find(unenrolled))
    end
  end

  ###########
  # Helpers #
  ###########
  def self.data_ok?(data)
    if data.include? nil
      Rails.logger.warn 'Network error. Course import cancelled.'
      return false
    end
    return true
  end

  def self.role_index
    %w(student instructor online_volunteer
       campus_volunteer wiki_ed_staff)
  end

  def self.assignment_hash(user, course_id, raw, article, role)
    {
      'user_id' => user['id'],
      'course_id' => course_id,
      'article_title' => raw['title'],
      'article_id' => article.nil? ? nil : article.id,
      'role' => role
    }
  end
end
