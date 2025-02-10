# frozen_string_literal: true

class LTILaunchController < ApplicationController

  def link_user
    unless current_user
      redirect_to root_path
      return
    end
    ltik = params[:ltik]
    ltiaas_domain = ENV['LTIAAS_DOMAIN']
    api_key = ENV['LTIAAS_API_KEY']
    lti_session = LTISession.new(ltiaas_domain, api_key, ltik)
    lti_session.send_account_created_signal
    redirect_to root_path
  end
end
