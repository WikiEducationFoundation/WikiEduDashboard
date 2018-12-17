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

# Alert for when an article under discretionary sanctions on Wikipedia has been
# edited.
class DiscretionarySanctionsEditAlert < Alert
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
      Resolve this alert if you want to be alerted again for future edits to
      the article. The Dashboard will issue a new alert only if there edits to
      this article that happen after the resolved alert was generated.
    EXPLANATION
  end
end
