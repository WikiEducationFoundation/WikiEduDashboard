# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"

#= Controller for adding multiple users to a course at once
class MassEnrollmentController < ApplicationController
  respond_to :html
  before_action :require_permissions

  def index
    @course = Course.find_by(slug: params[:course_id])
  end

  def add_users
    @course = Course.find_by(slug: params[:course_id])
    usernames_list = params[:usernames].lines.map(&:strip)
    @results = AddUsers.new(course: @course, usernames_list: usernames_list).add_all_at_once
    MassEnrollmentWorker.schedule_edits(course: @course,
                                        editing_user: current_user,
                                        enrollment_results: @results)
    render :index
  end
end
