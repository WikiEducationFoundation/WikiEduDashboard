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

# Alert for when a user has been blocked on English Wikipedia
class BlockedUserAlert < Alert
  def main_subject
    "#{user.username} was blocked on Wikipedia"
  end

  def url
    "https://en.wikipedia.org/wiki/Special:Log?type=block&user=&page=User%3A#{user.url_encoded_username}&wpdate=&tagfilter=&subtype="
  end

  def send_mails_to_concerned
    BlockedUserAlertMailer.send_mails_to_concerned(self)
    return if emails_disabled?
    update(email_sent_at: Time.zone.now)
  end
end
