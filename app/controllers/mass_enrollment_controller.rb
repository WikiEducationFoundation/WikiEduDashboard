# frozen_string_literal: true

require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/app/workers/update_course_worker"

#= Controller for adding multiple users to a course at once
class MassEnrollmentController < ApplicationController
  respond_to :html
  before_action :require_permissions

  def index
    @course = Course.find_by_slug(params[:course_id])
  end

  def add_users
    @course = Course.find_by_slug(params[:course_id])

    usernames_list = params[:usernames].lines.map(&:strip)
    @results = {}
    usernames_list.each do |username|
      @results[username] = add_user(username)
    end

    UpdateCourseWorker.schedule_edits(course: @course, editing_user: current_user)

    render :index
  end

  private

  def add_user(username)
    user = find_or_import_user(username)
    return { failure: 'Not an existing user.' } unless user
    JoinCourse.new(course: @course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE).result
  end

  def find_or_import_user(username)
    user = User.find_by(username: username)
    user = UserImporter.new_from_username(username, @course.home_wiki) if user.nil?
    user
  end
end
