# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/user_importer"

class AddUsers
  def initialize(course:, usernames_list:)
    @course = course
    @usernames_list = usernames_list
  end

  def add_all_at_once
    @results = {}
    @usernames_list.each do |username|
      add_one_by_one(username)
    end
    return @results
  end

  private

  def add_one_by_one(username)
    user = find_or_import_user(username) { return }
    @results[user.username] = JoinCourse.new(course: @course,
                                             user: user,
                                             role: CoursesUsers::Roles::STUDENT_ROLE).result
  end

  def find_or_import_user(username)
    user = User.find_by(username: username)
    user ||= UserImporter.new_from_username(username, @course.home_wiki)
    return user if user.present?

    @results[username] = { failure: 'Not an existing user.' }
    yield
  end
end
