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

# Alert for a request for a Wiki Expert to review an draft article or bibliography
class ReviewRequestAlert < Alert
  def main_subject
    return '' unless assignment
    "Review request: #{assignment.article_title} — #{course.slug}"
  end

  def url
    return '' unless assignment
    "#{assignment.sandbox_url}/Bibliography"
  end

  # The 'subject' for the Alert record is the Assignment id.
  def assignment
    @assignment ||= Assignment.find_by(id: subject_id)
  end

  def message
    "Ready for review: <a href=\"#{url}\">#{url}</a>"
  end
end
