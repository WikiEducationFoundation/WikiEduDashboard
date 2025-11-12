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

# Alert for when a new user move a sandbox into mainspace on Wikipedia,
# the edits are automatically tagged de-userfying.
class DeUserfyingAlert < Alert
  def main_subject
    "#{user.username} moved article #{details[:title]}#{ai_alerts_tag} from sandbox into mainspace"
  end

  def url
    "#{course.home_wiki.base_url}/w/index.php?title=Special:Log&logid=#{details[:logid]}"
  end

  def ai_alerts_tag
    return '' unless details[:ai_edit_alert_ids]
    " (#{details[:ai_edit_alert_ids].count} AI alerts)"
  end
end
