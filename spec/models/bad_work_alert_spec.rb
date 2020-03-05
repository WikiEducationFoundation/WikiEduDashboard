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
    create(:articles_course, course: course, article: article)
    courses_users = [
      { course_id: course.id, user_id: student.id, role: CoursesUsers::Roles::STUDENT_ROLE },
      { course_id: course.id, user_id: instructor.id, role: CoursesUsers::Roles::INSTRUCTOR_ROLE },
      { course_id: course.id, user_id: expert.id, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }
    ]
    CoursesUsers.create(courses_users)
  end

  let(:alert) do
    create(:bad_work_alert, user: instructor, course: course, article: article)
  end

  describe '#send_email' do
    it 'sends an email to the content expert with the correct subject' do
      expect(alert.email_sent_at).to be_nil
      alert.send_email
      expect(alert.reload.email_sent_at).not_to be_nil

      emails = ActionMailer::Base.deliveries
      expect(emails.length).to eq(1)

      email = emails.first
      expect(email.to_addresses.length).to eq(1)
      expect(email.to_addresses.first.address).to eq(expert.email)
      expect(email.subject).to include(article.title)
      expect(email.subject).to include(course.slug)
    end
  end
end
