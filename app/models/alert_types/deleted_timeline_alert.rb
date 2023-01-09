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

# Alert for a course that has too many deleted uploads
class DeletedTimelineAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course.url
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      It appears you have removed either the timeline, week or block from your course.
    EXPLANATION
  end
end