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

# Alert for a student edit whose AI-flagged text was already on the page, when
# an earlier edit that added that text is also flagged by Pangram. revision_id
# is the student's edit; the earlier edits are in details[:origin_edits].
# Created by CheckOriginEditsWithPangram.
class PreexistingAiTextAlert < Alert
  def main_subject
    '[PLACEHOLDER - subject line for an alert that AI-flagged text a student edit ' \
      "built on came from an earlier edit] Page: #{article&.title} — #{course&.title}"
  end

  def wiki
    article&.wiki || Wiki.default_wiki
  end

  def url
    diff_url(revision_id)
  end

  def page_url
    article&.url || url
  end

  def diff_url(rev_id)
    "#{wiki.base_url}/w/index.php?diff=#{rev_id}"
  end

  def article_title
    details[:article_title]
  end

  def ai_edit_alert
    AiEditAlert.find_by(id: details[:ai_edit_alert_id])
  end

  def origin_edits
    details[:origin_edits] || []
  end

  # Flagged earlier edits that did not already get an AI edit alert of their own.
  def flagged_origin_edits
    origin_edits.select { |edit| edit[:flagged] && !edit[:already_alerted] }
  end

  def resolvable?
    false
  end

  def send_alert_emails
    return if emails_disabled?
    return if course&.private
    return if AiEditAlert::NO_EMAIL_TYPES.include?(ai_edit_alert&.page_type)

    PreexistingAiTextAlertMailer.send_emails(self)
    update(email_sent_at: Time.zone.now)
  end
end
