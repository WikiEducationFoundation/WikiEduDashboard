# frozen_string_literal: true

class LtiLaunchController < ApplicationController
  # We need to allow iframe embedding for the LTI launch to work
  # We also need it for the related views
  after_action :allow_iframe

  # The LTI Session can raise two types of exceptions:
  # LtiaasClientError: Raised if any of the LTIAAS requests fail.
  # LtiGradingServiceUnavailable: Raised if the grading service is
  #   unavailable for the current LTI context.

  def init_lti_session
    # Starting LTI Session
    @ltik = params[:ltik]
    ltiaas_domain = ENV['LTIAAS_DOMAIN']
    api_key = ENV['LTIAAS_API_KEY']
    @lti_session = LtiSession.new(ltiaas_domain, api_key, @ltik)
    # Clearing ltik from session after successful processing
    # session.delete(:ltik)
    true
  end

  def launch
    unless current_user
      # Redirecting user to page requiring them to log in
      # You might want to append the ltik here, depending on whether or not
      # you want the user to remain in the iframe for the login process (if it's even possible)
      session['ltik'] = params[:ltik]
      redirect_to root_path
      return
    end

    init_lti_session

    # Linking LTI User
    @lti_session.link_lti_user(current_user)
    # Redirecting user to page confirming their account has been linked, training for now
    redirect_to "/training"
  end

  def deep_link_launch
    init_lti_session
    render "lti_launch/deep_link"
  end

  def deep_link_search
    @search = params[:query].present?
    @results = search_resources(params[:query])
    render "lti_launch/deep_link"
  end

  def deep_link_submit
    selection = params[:selection]
    raise "No selection" if selection.blank?
    type, id = selection.split(":")
    resource = type.constantize.find(id)

    form_html = @lti_session.build_and_submit_deep_link(resource)
    render html: form_html.html_safe
  end

  def search_resources(query)
    results = []

    TrainingModule.where("name LIKE :q OR slug LIKE :q OR description LIKE :q", q: "%#{query}%")
                  .limit(5).each do |t|
      results << { id: t.id, title: t.name, resource_type: "TrainingModule" }
    end

    Course.where("title LIKE :q OR slug LIKE :q OR description LIKE :q", q: "%#{query}%")
          .limit(5).each do |c|
      results << { id: c.id, title: c.title, resource_type: "Course" }
    end

    Campaign.where("title LIKE :q OR slug LIKE :q OR description LIKE :q", q: "%#{query}%")
            .limit(5).each do |c|
      results << { id: c.id, title: c.title, resource_type: "Campaign" }
    end

    results
  end

  private

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end