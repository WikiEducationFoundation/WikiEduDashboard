require 'rails_helper'

describe CohortsController do
  render_views

  describe '#students' do
    let(:course) { create(:course) }
    let(:cohort) { create(:cohort) }
    let(:student) { create(:user) }

    before do
      cohort.courses << course
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'returns a csv of student usernames' do
      get :students, slug: cohort.slug, format: :csv
      expect(response.body).to have_content(student.username)
    end
  end
end
