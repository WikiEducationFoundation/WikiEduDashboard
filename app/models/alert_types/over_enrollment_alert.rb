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

# Alert for a course that has too many enrolled students
class OverEnrollmentAlert < Alert
  # Wiki Education has a maximum course size we will support.
  # We also generate alerts if a course has significant more students than expected.
  MAX_ENROLLMENT = 100
  MAX_UNEXPECTED_STUDENTS = 5

  def main_subject
    "#{course.slug} — #{course.user_count} students"
  end

  def url
    course_url
  end

  def resolvable?
    !resolved
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolve this alert only if you've changed the expected student count for the course
      and there aren't more than #{MAX_ENROLLMENT}. If you resolve it, the Dashboard will
      create a new alert if it becomes over-enrolled again.
    EXPLANATION
  end
end
