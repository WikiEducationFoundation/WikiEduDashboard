# frozen_string_literal: true

require 'rails_helper'

describe 'Private courses' do
  let(:course) { create(:course, private: true) }
  let(:user) { create(:user) }
  before do
    login_as user
    stub_oauth_edit
  end

  context 'when the can edit the course the course' do
    before do
      JoinCourse.new(course: course, user: user, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'renders the course normally' do
      visit "/courses/#{course.slug}"
      expect(page.status_code).to eq(200)
    end
  end
  context 'when the user is not participating in the course' do
    it 'raises a 404 error' do
      expect { visit "/courses/#{course.slug}" }.to raise_error(ActionController::RoutingError)
    end
  end
end
