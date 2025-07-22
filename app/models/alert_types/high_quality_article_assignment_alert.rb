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

# Alert for when Good or Featured on Wikipedia has been chosen
# as an assignment by a student.
class HighQualityArticleAssignmentAlert < Alert
  def main_subject
    "[Wiki Education: #{course&.title}] #{article.title} is a well-developed article"
  end

  def url
    article.url
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolve this alert if you want to be alerted again for future assignments to
      the article in the same course. The Dashboard will issue a new alert only if
      there are assignments to this article in the same course that happen after the
      resolved alert was generated.
    EXPLANATION
  end

  def email_involved_users
    return if emails_disabled?
    HighQualityArticleAssignmentMailer.send_email(self)
    update(email_sent_at: Time.zone.now)
  end
end
