# frozen_string_literal: true

#= Controller for adding multiple users to a course at once
class RequestedAccountsController < ApplicationController
  respond_to :html
  before_action :set_course
  before_action :check_creation_permissions, only: [:create_accounts]

  def request_account
    redirect_if_passcode_invalid { return }
    # If there is already a request for a certain username for this course, then
    # it's probably the same user who put in the wrong email the first time.
    # Just overwrite the email with the new one in this case.
    existing_request = RequestedAccount.find_by(course: @course, username: params[:username])
    if existing_request
      existing_request.update_attribute(:email, params[:email])
      return
    end

    RequestedAccount.create(course: @course, username: params[:username], email: params[:email])
  end

  def index; end

  def create_accounts
    @results = []
    @course.requested_accounts.each do |requested_account|
      creation_attempt = CreateRequestedAccount.new(requested_account, current_user)
      result = creation_attempt.result
      @results << result
      next unless result[:success]
      user = creation_attempt.user
      JoinCourse.new(course: @course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
  end

  private

  def check_creation_permissions
    return if user_signed_in? && current_user.can_edit?(@course)
    exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
    raise exception
  end

  def set_course
    @course = Course.find_by_slug(params[:course_slug])
  end

  def redirect_if_passcode_invalid
    return if passcode_valid?
    redirect_to '/errors/incorrect_passcode'
    yield
  end

  def passcode_valid?
    return true if @course.passcode.nil?
    params[:passcode] == @course.passcode
  end
end
