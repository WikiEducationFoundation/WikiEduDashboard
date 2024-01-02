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

# Receive an alert when a course has no enrolled students even after it has started.
class UntrainedStudentsAlert < Alert
  def main_subject
    "Student training for #{course.slug}"
  end

  def url
    course_url
  end

  def send_email
    return if emails_disabled?
    UntrainedStudentsAlertMailer.send_email(self)
    update(email_sent_at: Time.zone.now)
  end

  def from_user
    @from_user ||= SpecialUsers.classroom_program_manager
  end

  def reply_to
    from_user&.email
  end
end
