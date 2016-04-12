class ApplicationMailer < ActionMailer::Base
  default from: "Notifications <sender@#{ENV['SENDER_EMAIL_ADDRESS']>"
  layout 'mailer'
end
