# frozen_string_literal: true

# == Schema Information
#
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

# Alert for when an article has been nominated for DYK on English Wikipedia
class DYKNominationAlert < Alert
  def main_subject
    "#{article.title} — #{course&.slug}"
  end

  def url
    article.url
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolving this alert means the article no longer has an active DYK
      nomination. A new alert will be generated if it is nominated again.
    EXPLANATION
  end

  def email_instructors_and_wikipedia_experts
    return if emails_disabled?
    DidYouKnowAlertMailer.send_dyk_email(self)
    update(email_sent_at: Time.zone.now)
  end
end
