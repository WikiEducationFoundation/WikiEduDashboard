# frozen_string_literal: true

require 'rails_helper'

# The only surface that reads or writes the real title and institution of a
# privacy-mode course.
describe 'Confidential course details', type: :request do
  let(:course) do
    create(:course, title: 'Course 1', school: 'Confidential', term: 'Fall 2026',
                    slug: 'Confidential/Course_1_(Fall_2026)')
  end
  let(:instructor) { create(:user, username: 'Instructor') }
  let(:admin) { create(:admin, username: 'Admin') }

  before do
    create(:confidential_course_detail, course:, real_title: 'Introduction to Biology',
                                        real_school: 'State University')
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  describe 'GET show' do
    it 'returns the real values to an admin' do
      login_as admin
      get "/confidential_course_details/#{course.id}"
      expect(response.body).to include('Introduction to Biology')
      expect(response.body).to include('State University')
    end

    it 'refuses the course instructor' do
      login_as instructor
      get "/confidential_course_details/#{course.id}"
      expect(response.body).not_to include('Introduction to Biology')
    end

    it 'refuses a logged-out visitor' do
      get "/confidential_course_details/#{course.id}"
      expect(response.body).not_to include('Introduction to Biology')
    end
  end

  describe 'PUT update' do
    it 'lets an admin correct the real values' do
      login_as admin
      put "/confidential_course_details/#{course.id}",
          params: { confidential_course_detail: { real_title: 'Advanced Biology' } }
      expect(course.confidential_course_detail.reload.real_title).to eq('Advanced Biology')
    end

    it 'does not let an admin change the sequence the slug was built from' do
      login_as admin
      put "/confidential_course_details/#{course.id}",
          params: { confidential_course_detail: { sequence: 99, real_title: 'Advanced Biology' } }
      expect(course.confidential_course_detail.reload.sequence).not_to eq(99)
    end

    it 'refuses the course instructor' do
      login_as instructor
      put "/confidential_course_details/#{course.id}",
          params: { confidential_course_detail: { real_title: 'Advanced Biology' } }
      expect(course.confidential_course_detail.reload.real_title).to eq('Introduction to Biology')
    end
  end
end
