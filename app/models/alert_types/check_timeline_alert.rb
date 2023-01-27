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

# Alert for a course whose timeline is deleted
class CheckTimelineAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolving this alert means the course has some timeline. A new
      alert will be generated if it again nominated or tagged for timeline deletion.
    EXPLANATION
  end

  def self.default_message
    'All the training modules have been removed from the course'
  end
end
