# frozen_string_literal: true

class CheckWikiEmailWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.check(user:)
    perform_async(user.id)
  end

  def perform(user_id)
    user = User.find(user_id)
    emailable = CheckWikiEmail.new(user: user, wiki: Wiki.default_wiki).emailable?
    return if emailable
    WikiEmailMailer.send_email_warning(user)
  end
end
