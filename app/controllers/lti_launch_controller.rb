# frozen_string_literal: true

class LtiLaunchController < ApplicationController

  def link_user
    unless current_user
      # Redirect user to page requiring them to log in
      redirect_to root_path
      return
    end

    ltik = params[:ltik]
    ltiaas_domain = ENV['LTIAAS_DOMAIN']
    api_key = ENV['LTIAAS_API_KEY']

    lti_session = LtiSession.new(ltiaas_domain, api_key, ltik)
    lti_session.send_account_created_signal

    # Redirect user to page confirming their account has been linked
    redirect_to root_path
  end
end
