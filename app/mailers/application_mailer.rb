class ApplicationMailer < ActionMailer::Base
  default from: ENV['SENDER_EMAIL_ADDRESS']
  layout 'mailer'
end
