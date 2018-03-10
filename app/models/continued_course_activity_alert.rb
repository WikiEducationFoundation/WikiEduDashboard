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

# Alert for a course that has been editing in mainspace after the end date
class ContinuedCourseActivityAlert < Alert
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
      Resolve this alert if you've changed the end date for the course. The
      Dashboard will create a new alert if there edits after the new end date.
    EXPLANATION
  end
end
