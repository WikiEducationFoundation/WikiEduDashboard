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

# Alert for when an article has been nominated for deletion on English Wikipedia
class AiEditAlert < Alert
  def self.generate_alert_from_pangram(revision_id:, user_id:, course_id:,
                                       article_id:, pangram_details:)
    alert = create!(revision_id:,
                    user_id:,
                    course_id:,
                    article_id:,
                    details: pangram_details)
    alert.send_alert_emails
  end

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

  def send_alert_emails
    # Lists of references are where we see
    # false positives, so we won't send
    # emails for the Bibliography exercise sandbox
    return if page_type == :bibliography

    AiEditAlertMailer.send_emails(self,
                                  page_repeat: same_page_repeat?,
                                  user_repeat: same_user_repeat?)
    update(email_sent_at: Time.zone.now)
  end

  # Is there another alert for the same
  # course and article? If so, this could
  # might have triggered from a different
  # edit but with the same AI-detected text.
  def same_page_repeat?
    AiEditAlert.where(course_id:, article_id:).count > 1
  end

  # Is there another alert for the same
  # course and user, long enough ago that they
  # should have gotten an earlier message
  # telling them to avoid AI?
  def same_user_repeat?
    AiEditAlert.where(course_id:, user_id:).first.created_at < 1.day.ago
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
    when /^User:/ # catchall for other sandboxes
      :sandbox
    else
      :unknown
    end
  end
end
