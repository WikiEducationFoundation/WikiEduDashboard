class ApplicationMailer < ActionMailer::Base
  default from: ENV['SENDER_EMAIL_ADDRESS']
  layout 'mailer'
  add_template_helper(SurveysUrlHelper)
end
