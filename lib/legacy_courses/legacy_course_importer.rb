require "#{Rails.root}/lib/wiki"
require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/lib/importers/cohort_importer"

#= Imports and updates courses from Wikipedia into the dashboard database
class LegacyCourseImporter
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
    require "#{Rails.root}/lib/legacy_courses/wiki_legacy_courses"
    WikiLegacyCourses.get_course_info course_id
  end

  def self.import_courses(raw_ids, data)
    # Encountered an API error; cancel course import for today
    return unless data_ok?(data)

    courses = []
    participants = {}
    listed_ids = raw_ids.values.flatten

    # Delist courses that have been deleted
    handle_deleted_courses(listed_ids, data)

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
    require "#{Rails.root}/lib/legacy_courses/legacy_course_reviewers"
    reviewers = LegacyCourseReviewers.find_reviewers(group)
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
    all_assignments = build_assignments course_id, group_flat
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

  def self.enroll_users(users, enrolled, course)
    users.each do |u|
      next() unless enrolled.include? u['id']
      role = role_index.index(u['role'])
      role = 4 if u['username'].include? '(Wiki Ed)'
      CoursesUsers.new(user_id: u['id'], course: course, role: role).save
    end
  end

  def self.build_assignments(course_id, group_flat)
    require "#{Rails.root}/lib/legacy_courses/legacy_course_assignments"
    # Add assigned articles
    assignments = LegacyCourseAssignments
                  .build_assignments_from_group_flat(course_id, group_flat)
    assignments
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
end
