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

# Alert for an instructor marks a particular article as including work
# that requires Wiki Expert intervention
class BadWorkAlert < Alert
  before_save :set_default_values

  def main_subject
    "#{article.title} — #{course&.slug}"
  end

  def url
    "#{course_url}/articles/edited?showArticle=#{article.id}"
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolving this alert means the article work in question has been addressed
      with the students, the instructor, or the community.
    EXPLANATION
  end

  private

  def set_default_values
    link = "\n<a href='#{url}'>#{article.title}</a>"
    self.message = "BadWorkAlert for #{article.title}\n#{message}#{link}"
    self.target_user_id = content_experts.first&.id
  end
end
