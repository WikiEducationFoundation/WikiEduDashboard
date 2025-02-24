# frozen_string_literal: true

class LtiLaunchController < ApplicationController
  # We need to allow iframe embedding for the LTI launch to work
  # We also need it for the related views
  after_action :allow_iframe

  # The LTI Session can raise two types of exceptions:
  # LtiaasClientError: Raised if any of the LTIAAS requests fail
  # LtiGradingServiceUnavailable: Raised if the grading service is unavailable for the current LTI context

  def launch
    unless current_user
      # Redirecting user to page requiring them to log in
      # You might want to append the ltik here, depending on whether or not
      # you want the user to remain in the iframe for the login process (if it's even possible)
      redirect_to root_path
      return
    end
    # Starting LTI Session
    ltik = params[:ltik]
    ltiaas_domain = ENV['LTIAAS_DOMAIN']
    api_key = ENV['LTIAAS_API_KEY']
    lti_session = LtiSession.new(ltiaas_domain, api_key, ltik)
    # Linking LTI User
    link_lti_user(lti_session)
    # Redirecting user to page confirming their account has been linked
    redirect_to root_path
  end

  private
  def link_lti_user(lti_session)
    user_lti_id = lti_session.user_lti_id
    lms_id = lti_session.lms_id
    lms_family = lti_session.lms_family
    context_id = lti_session.context_id
    # Checking if LTI User already exists
    return if !LtiContext.find_by(user: current_user, user_lti_id: user_lti_id, lms_id: lms_id, context_id: context_id).nil?
    # Sending account created signal
    # You can pass the User Wikipedia ID as parameter to this method to generate a comment in the grade
    # Example: lti_session.send_account_created_signal(123)
    lti_session.send_account_created_signal(current_user.username)
    # Creating LTI User
    LtiContext.create(user: current_user, user_lti_id: user_lti_id, lms_id: lms_id, lms_family: lms_family, context_id: context_id)
  end

  private
  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
