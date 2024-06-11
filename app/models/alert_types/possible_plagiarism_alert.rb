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
  def self.new_from_revision(revision, submission_id)
    return if PossiblePlagiarismAlert.exists?(revision:)

    user = revision.user
    course = user.courses_users.last.course
    article = revision.article
    details = { submission_id: }
    create(user:, course:, article:, details:)
  end

  def main_subject
    "Possible plagiarism from #{@course.title}"
  end

  def url
    "https://copypatrol.wmcloud.org/ithenticate/#{copypatrol_submission_id}"
  end

  def copypatrol_submission_id
    details[:submission_id]
  end
end
