# frozen_string_literal: true

#= Controller for requesting new wiki accounts and processing those requests
class RequestedAccountsCampaignsController < ApplicationController
  respond_to :html
  before_action :set_campaign
  before_action :check_requested_account_permission
  before_action :check_creation_permissions,
                only: %i[index create_accounts enable_account_requests destroy]
  # This creates (or updates) a RequestedAccount, which is a username and email
  # for a user who wants to create a wiki account (but may not be able to do so
  # because of a shared IP that has hit the new account limit).
  def request_account
    redirect_if_passcode_invalid { return }
    # If there is already a request for a certain username for this course, then
    # it's probably the same user who put in the wrong email the first time.
    # Just overwrite the email with the new one in this case.
    handle_existing_request { return }
    requested = RequestedAccount.create(campaign: @campaign,
                                        username: params[:username],
                                        email: params[:email])
    unless params[:create_account_now] == 'true'
      render json: { message: I18n.t('courses.new_account_submitted') }
      return
    end
    # TODO: render relevant json to be handled on the frontend
    # { success: 'some message'} or { failure: 'some message' }
    result = create_account(requested)
    if result[:success] # TODO: handle both success and failure
      render json: { message: result.values.first }
    else
      render json: { message: result.values.first }, status: 500
    end
  end

  # Sets the flag on a course so that clicking 'Sign Up' opens the Request Account
  # modal instead of redirecting to the mediawiki account creation flow.
  def enable_account_requests
    @campaign.courses.each do |course|
      course.flags[:register_accounts_campaigns] = true
      course.save
    end
    redirect_back(fallback_location: root_path)
    return
  end

  def disable_account_requests
    @campaign.courses.each do |course|
      course.flags.delete(:register_accounts_campaigns)
      course.save
    end
    redirect_back(fallback_location: root_path)
    return
  end

  # List of requested accounts for a course.
  def index; end

  def destroy
    # raise exception unless requestedaccount belongs to course
    requested_account = RequestedAccount.find_by(id: params[:id])
    requested_account_course = requested_account.course_id
    campaigns_ids = Course.find_by(id: requested_account_course).campaigns.ids
    raise_unauthorized_exception unless campaigns_ids.include?(@campaign.id)
    requested_account.delete
    redirect_back fallback_location: '/'
  end

  # Try to create each of the requested accounts for a course, and show the
  # result for each.
  def create_accounts
    @results = []
    @campaign.requested_accounts.each do |requested_account|
      @results << create_account(requested_account)
    end
  end

  private

  def create_account(requested_account)
    creation_attempt = CreateRequestedAccount.new(requested_account, current_user)
    result = creation_attempt.result
    return result unless result[:success]
    # If it was successful, enroll the user in the course
    # user = creation_attempt.user
    # JoinCourse.new(course: @course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE)
    # result
  end

  def check_creation_permissions
    return if user_signed_in? && @campaign && current_user.can_edit?(@campaign)
    raise_unauthorized_exception
  end

  def raise_unauthorized_exception
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def set_campaign
    @campaign = Campaign.find_by(slug: params[:campaign_slug])
  end

  # def redirect_if_passcode_invalid
  #   return if passcode_valid?
  #   redirect_to '/errors/incorrect_passcode'
  #   yield
  # end
  #
  # def passcode_valid?
  #   return true if @course.passcode.nil?
  #   params[:passcode] == @course.passcode
  # end

  def check_requested_account_permission
    return if Features.enable_account_requests?
    raise_unauthorized_exception
  end

  def handle_existing_request
    existing_request = RequestedAccount.find_by(campaign: @campaign, username: params[:username])
    if existing_request
      existing_request.update_attribute(:email, params[:email])
      yield
    end
  end
end
