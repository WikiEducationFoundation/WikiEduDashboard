# frozen_string_literal: true

#= Controller for requesting new wiki accounts and processing those requests
class RequestedAccountsCampaignsController < ApplicationController
  respond_to :html
  before_action :set_campaign
  before_action :check_requested_account_permission
  before_action :check_creation_permissions,
                only: %i[index create_accounts enable_account_requests]

  # Sets the flag on a course so that clicking 'Sign Up' opens the Request Account
  # modal instead of redirecting to the mediawiki account creation flow.
  def enable_account_requests
    @campaign.update(register_accounts: true)
    redirect_back(fallback_location: root_path)
  end

  def disable_account_requests
    @campaign.update(register_accounts: false)
    redirect_back(fallback_location: root_path)
  end

  # List of requested accounts for a course.
  def index; end

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
    user = creation_attempt.user
    JoinCourse.new(course: requested_account.course, user: user,
                   role: CoursesUsers::Roles::STUDENT_ROLE)
    result
  end

  def check_creation_permissions
    return if user_signed_in? && @campaign && current_user.admin?
    raise_unauthorized_exception
  end

  def raise_unauthorized_exception
    raise ActionController::InvalidAuthenticityToken, 'Unauthorized'
  end

  def set_campaign
    @campaign = Campaign.find_by(slug: params[:campaign_slug])
  end

  def check_requested_account_permission
    return if Features.enable_account_requests?
    raise_unauthorized_exception
  end
end
