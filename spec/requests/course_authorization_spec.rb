# frozen_string_literal: true

require 'rails_helper'

describe 'Course authorization', type: :request do
  let(:instructor) { create(:user, username: 'OwnInstructor') }
  let(:own_course) { create(:course, slug: 'Own_School/Own_Course_(term)') }
  let(:other_course) { create(:course, slug: 'Other_School/Other_Course_(term)') }

  before do
    stub_wiki_validation
    create(:courses_user, course: own_course, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  # require_permissions used to check params[:id] before the route's own
  # :slug or :course_id, so ?id=<own course> passed for another course.
  describe 'naming an editable course in a query param' do
    before { login_as instructor }

    it 'does not open mass enrollment for another course' do
      get "/mass_enrollment/#{other_course.slug}", params: { id: own_course.slug }
      expect(response.status).to eq(401)
    end

    it 'does not open assignment progress for another course' do
      get "/courses/#{other_course.slug}/assignment_progress.json", params: { id: own_course.slug }
      expect(response.status).to eq(401)
    end

    it 'does not open another course\'s timeline for editing' do
      post "/courses/#{other_course.slug}/timeline",
           params: { id: own_course.slug, weeks: [] }, as: :json
      expect(response.status).to eq(401)
    end
  end
end
