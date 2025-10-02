# frozen_string_literal: true

# == Schema Information
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

# Alert for suspected AI-generated text on edited pages
class AiEditAlert < Alert
  ####################
  # Alert generation #
  ####################

  def self.generate_alert_from_pangram(revision_id:, user_id:, course_id:,
                                       article_id:, pangram_details:)
    details = pangram_details
    add_same_page_alert(course_id, article_id, details)
    add_same_user_alert(course_id, user_id, details)
    alert = create!(revision_id:,
                    user_id:,
                    course_id:,
                    article_id:,
                    details:)

    alert.send_alert_emails
  end

  # Is there another alert for the same
  # course and article? If so, this could
  # might have triggered from a different
  # edit but with the same AI-detected text.
  def self.add_same_page_alert(course_id, article_id, details)
    prior_alert = AiEditAlert.find_by(course_id:, article_id:)
    return unless prior_alert

    details[:prior_alert_for_page] = prior_alert.id
  end

  # Is there another alert for the same
  # course and user, long enough ago that they
  # should have gotten an earlier message
  # telling them to avoid AI?
  def self.add_same_user_alert(course_id, user_id, details)
    prior_alerts = AiEditAlert.where(course_id:, user_id:).where('created_at < ?', 1.day.ago)
    return unless prior_alerts.any?

    details[:prior_alert_for_user] = prior_alerts.last.id
  end

  ####################
  # Instance methods #
  ####################

  def main_subject
    "Suspected AI edit: #{article&.title} — #{course&.title}"
  end

  def repeat_page_subject
    "Same-page AI edit alert: #{article&.title} — #{course&.title}"
  end

  def repeat_user_subject
    "Another suspected AI edit: #{user.username} — #{course&.title}"
  end

  def wiki
    article&.wiki || Wiki.default_wiki
  end

  def url
    "#{wiki.base_url}/w/index.php?diff=#{revision_id}"
  end

  def page_url
    article&.url || url
  end

  def pangram_url
    details[:pangram_share_link]
  end

  def pangram_prediction
    details[:pangram_prediction]
  end

  def average_ai_likelihood
    details[:average_ai_likelihood]
  end

  def max_ai_likelihood
    details[:max_ai_likelihood]
  end

  def predicted_ai_window_count
    details[:predicted_ai_window_count]
  end

  def predicted_llm
    details[:predicted_llm]
  end

  def followup_template
    'ai_edit_alert'
  end

  def followup_link
    "https://#{ENV['dashboard_url']}/alert_followup/#{id}"
  end

  def article_title
    details[:article_title]
  end

  NO_EMAIL_TYPES = [
    :bibliography, # Lists of references are where we see false positives
    :peer_review # This is intended for a fellow student so no need to flag it
  ].freeze
  def send_alert_emails
    return if NO_EMAIL_TYPES.include? page_type

    AiEditAlertMailer.send_emails(self)
    update(email_sent_at: Time.zone.now)
  end

  def prior_alert_id_for_page
    details[:prior_alert_for_page]
  end

  def prior_alert_id_for_user
    details[:prior_alert_for_user]
  end

  def page_type
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
    else
      :unknown
    end
  end
end
