class ApplicationMailer < ActionMailer::Base
  default from: "Notifications <sender@#{ENV['mailgun_domain']}>"
  layout 'mailer'
end
