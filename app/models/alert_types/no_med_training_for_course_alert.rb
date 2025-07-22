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

# Alert for when students in a course edit WikiProject Medicne articles
# but the medical content training is not assigned for the course.
class NoMedTrainingForCourseAlert < Alert
  def main_subject
    "Course #{course.title} was not assigned the medical training module \
    while article #{article.title} is a WP med article ."
  end

  def url
    course_url
  end
end
