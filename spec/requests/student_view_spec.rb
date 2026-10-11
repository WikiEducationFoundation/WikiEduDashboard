# frozen_string_literal: true

require 'rails_helper'

describe 'Course data in student view', type: :request do
  let(:course) do
    create(:course, slug: 'School/Student_view_(Fall_2026)', passcode: 'secretcode',
                    start: 1.week.from_now, end: 4.months.from_now,
                    timeline_start: 1.week.from_now, timeline_end: 4.months.from_now)
  end
  # A recent wiki token skips the course page's OAuth credentials check.
  let(:instructor) do
    create(:user, username: 'Prof', email: 'prof@example.edu', wiki_token: 'token')
  end
  let(:student) { create(:user, username: 'Student', email: 'student@example.edu') }
  let(:week) { create(:week, course:, order: 0) }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training A', kind: 0) }

  before do
    create(:courses_user, course:, user: instructor, real_name: 'Pat Professor',
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course:, user: student, real_name: 'Sam Student',
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:block, week:, order: 0, training_module_ids: [training.id])
  end

  def course_data(params = {})
    get "/courses/#{course.slug}/course.json", params: params
    JSON.parse(response.body)['course']
  end

  def users_data(params = {})
    get "/courses/#{course.slug}/users.json", params: params
    JSON.parse(response.body).dig('course', 'users').index_by { |user| user['id'] }
  end

  let(:student_view) { { view_as: 'student' } }

  context 'as the instructor' do
    before { login_as instructor }

    it 'sends the passcode and instructor-only flags normally' do
      expect(course_data).to include('passcode' => 'secretcode', 'canUploadSyllabus' => true)
    end

    it 'sends what a student gets with view_as=student' do
      expect(course_data(student_view)).to include('passcode' => '****',
                                                   'canUploadSyllabus' => false)
      expect(course_data(student_view)).not_to have_key('passcode_required')
    end

    it 'sends real names, emails and student progress normally' do
      users = users_data
      expect(users[student.id]).to include('real_name' => 'Sam Student',
                                           'course_training_progress_assigned_count' => 1)
      expect(users[instructor.id]).to include('email' => 'prof@example.edu')
    end

    it 'leaves out what students do not see with view_as=student' do
      users = users_data(student_view)
      expect(users[student.id]).not_to have_key('real_name')
      expect(users[student.id]).not_to have_key('course_training_progress_assigned_count')
      expect(users[instructor.id]).not_to have_key('email')
    end

    it 'still sends what students do see with view_as=student' do
      users = users_data(student_view)
      expect(users[instructor.id]).to include('real_name' => 'Pat Professor',
                                              'course_training_progress_assigned_count' => 1)
    end
  end

  context 'as a student' do
    before { login_as student }

    it 'gets the same course data with or without view_as=student' do
      expect(course_data(student_view)).to eq(course_data)
    end

    it 'gets the same users data with or without view_as=student' do
      expect(users_data(student_view)).to eq(users_data)
    end
  end

  context 'as a signed-in visitor' do
    before { login_as create(:user, username: 'Visitor') }

    it 'gets nothing extra with view_as=student' do
      expect(course_data(student_view)).not_to have_key('survey_notifications')
      expect(users_data(student_view)[instructor.id]).not_to have_key('real_name')
    end
  end
end
