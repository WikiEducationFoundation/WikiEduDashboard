# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "dashboard@#{ENV['dashboard_url']}"
  layout 'mailer'
  add_template_helper(SurveysUrlHelper)
end
