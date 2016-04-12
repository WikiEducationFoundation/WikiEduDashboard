class ApplicationMailer < ActionMailer::Base
  default from: ENV['SENDER_EMAIL_ADDRESS'] || 'surveys@wikiedu.org'
  layout 'mailer'
end
