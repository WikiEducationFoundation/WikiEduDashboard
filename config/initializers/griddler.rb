require './lib/email_processor'

Griddler.configure do |config|
  config.email_service = :mailgun
end
