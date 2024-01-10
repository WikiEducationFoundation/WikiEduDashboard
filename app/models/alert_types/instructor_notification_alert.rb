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

# Alert for when the first student enrolls in a classroom program course.
class InstructorNotificationAlert < Alert
  def main_subject
    'New Notification from Admin'
  end

  def url
    course_url
  end

  def send_email
    return if emails_disabled?
    InstructorNotificationMailer.send_email(self)
    update(email_sent_at: Time.zone.now)
  end

  def reply_to
    User.find_by(id: user_id)&.email
  end
end
