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

class EarlyEnrollmentAlert < Alert
  def wiki_experts_email
    CoursesUsers.where(course:, user: SpecialUsers.wikipedia_experts,
                       role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
                .includes(:user).pluck('users.email')
  end

  def send_email
    return if emails_disabled?

    EarlyEnrollmentMailer.send_email(self)
    update(email_sent_at: Time.zone.now)
  end

  def url
    course_url
  end

  def main_subject
    "EarlyEnrollmentAlert: #{course.slug}"
  end
end
