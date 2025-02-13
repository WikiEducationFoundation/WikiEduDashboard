# frozen_string_literal: true

class LtiLaunchController < ApplicationController

  def launch
    unless current_user
      # Redirecting user to page requiring them to log in
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
    # Checking if LTI User already exists
    return if !LtiUser.find_by(user: current_user, user_lti_id: user_lti_id, lms_id: lms_id).nil?
    # Sending account created signal
    lti_session.send_account_created_signal
    # Creating LTI User
    LtiUser.create(user: current_user, user_lti_id: user_lti_id, lms_id: lms_id, lms_family: lms_family)
  end
end
