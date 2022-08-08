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

require 'rails_helper'

describe BadWorkAlert do
  let(:course) { create(:course) }
  let(:student) { create(:user, email: 'student@example.edu') }
  let(:instructor) { create(:instructor, email: 'instructor@example.edu') }
  let(:expert) { create(:admin, email: 'admin-expert@example.edu', greeter: true) }
  let(:article) { create(:article) }

  before do
    create(:articles_course, course:, article:)
    courses_users = [
      { course_id: course.id, user_id: student.id, role: CoursesUsers::Roles::STUDENT_ROLE },
      { course_id: course.id, user_id: instructor.id, role: CoursesUsers::Roles::INSTRUCTOR_ROLE },
      { course_id: course.id, user_id: expert.id, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }
    ]
    CoursesUsers.create(courses_users)
  end

  it 'should create a new alert with the message and target user set' do
    alert = create(:bad_work_alert, user: instructor, course:, article:)
    expect(alert.message).to include("BadWorkAlert for #{article.title}")
    expect(alert.message).to include(alert.url)
    expect(alert.target_user_id).to equal(expert.id)
  end

  it 'should include a message if specified' do
    message = 'a personalized message from the instructor'
    alert = create(:bad_work_alert,
                   user: instructor, course:, article:, message:)

    expect(alert.message).to include(message)
  end
end
