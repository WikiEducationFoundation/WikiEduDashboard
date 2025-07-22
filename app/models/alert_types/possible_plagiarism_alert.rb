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

# Alert for course revision flagged as possible plagiarism by CopyPatrol
class PossiblePlagiarismAlert < Alert
  def main_subject
    "Possible plagiarism from #{course&.title}"
  end

  def url
    "https://copypatrol.wmcloud.org/ithenticate/#{copypatrol_submission_id}"
  end

  def copypatrol_submission_id
    details[:submission_id]
  end

  def revision_id
    details[:mw_rev_id]
  end

  def wiki
    @wiki ||= Wiki.find details[:wiki_id]
  end

  def diff_url
    return if article.nil?
    title = article.escaped_full_title
    "#{wiki.base_url}/w/index.php?title=#{title}&diff=prev&oldid=#{revision_id}"
  end
end
