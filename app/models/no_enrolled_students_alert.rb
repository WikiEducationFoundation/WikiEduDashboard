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

# Alert for a course that has no enrolled students after it is underway
class NoEnrolledStudentsAlert < Alert
  def main_subject
    "Enrolling students for #{course.slug}"
  end

  def url
    course_url
  end

  def send_email
    return if emails_disabled?
    NoEnrolledStudentsAlertMailer.email(self).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end

  def from_user
    @from_user ||= SpecialUsers.classroom_program_manager
  end

  def reply_to
    from_user&.email
  end
end
