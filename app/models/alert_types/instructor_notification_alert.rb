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
  def subject=(subject_text)
    self.details ||= {}
    self.details[:subject] = subject_text
  end

  def subject
    details.present? ? details[:subject] : nil
  end

  def url
    course_url
  end

  # deliver the actual email immediately
  def send_email
    return if emails_disabled?
    InstructorNotificationMailer.send_email(self)
    update(email_sent_at: Time.zone.now)
  end

  # returns the email of the sender
  def sender_email
    User.find_by(id: user_id)&.email
  end

  # not used but required to be implemented (Subject is Dynamic)
  def main_subject
    "Admin sent you a message"
  end
end
