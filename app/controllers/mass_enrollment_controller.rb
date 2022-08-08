# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"
require_dependency "#{Rails.root}/lib/errors/mass_enrollment_errors"
require_dependency "#{Rails.root}/lib/errors/rescue_errors"

#= Controller for adding multiple users to a course at once
class MassEnrollmentController < ApplicationController
  include Errors::MassEnrollmentErrors

  respond_to :html
  before_action :require_permissions

  def index
    @course = Course.find_by(slug: params[:course_id])
  end

  def add_users
    @course = Course.find_by(slug: params[:course_id])
    usernames_list = params[:usernames].lines.map(&:strip)
    raise TooManyUsersError if too_many_users?(usernames_list)

    @results = AddUsers.new(course: @course, usernames_list:).add_all_at_once
    MassEnrollmentWorker.schedule_edits(course: @course,
                                        editing_user: current_user,
                                        enrollment_results: @results)
    render :index
  rescue TooManyUsersError => e
    render plain: e.message, status: :unauthorized
  end

  private

  MAX_COURSE_USERS = 150
  def too_many_users?(usernames_list)
    return false if @course.flags[:no_max_users]
    @course.students.count + usernames_list.count > MAX_COURSE_USERS
  end
end
