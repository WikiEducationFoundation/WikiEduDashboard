# frozen_string_literal: true

# Classifies the page an AI alert is about from details[:article_title], for
# the alert types that are about a student's edit to a page.
module AiAlertPageType
  # Page types whose AI alerts send no emails.
  NO_EMAIL_TYPES = [
    :bibliography, # Lists of references are where we see false positives
    :peer_review # This is intended for a fellow student so no need to flag it
  ].freeze

  def page_type # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    case article_title
    when /Choose an Article/
      :choose_an_article
    when /Evaluate an Article/
      :evaluate_an_article
    when %r{/Bibliography}
      :bibliography
    when %r{/Outline}
      :outline
    when /Peer Review/
      :peer_review
    when /^User:/ # catchall for other sandboxes
      :sandbox
    when /^Draft:/
      :draft
    when /^Talk:/
      :talk_page
    when /^User talk:/
      :user_talk
    when /^Template talk:/
      :template_talk
    when /^[^:]+$/ # match titles without ':'
      :mainspace
    else
      :unknown
    end
  end
end
