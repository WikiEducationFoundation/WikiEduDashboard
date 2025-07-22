# frozen_string_literal: true

require 'rails_helper'

describe 'Private courses' do
  let(:course) { create(:course, private: true) }
  let(:user) { create(:user) }

  before do
    login_as user
    stub_oauth_edit
    course.campaigns << Campaign.first
  end

  context 'when the user is enrolled in the course' do
    before do
      JoinCourse.new(course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'renders the course normally' do
      visit "/courses/#{escaped_slug course.slug}"
      expect(page.status_code).to eq(200)
    end
  end

  context 'when the user is an admin' do
    let(:user) { create(:admin) }

    it 'renders the course normally' do
      visit "/courses/#{escaped_slug course.slug}"
      expect(page.status_code).to eq(200)
    end
  end

  context 'when the user is not participating in the course' do
    it 'raises a 404 error' do
      expect { visit "/courses/#{escaped_slug course.slug}" }
        .to raise_error(ActionController::RoutingError)
    end
  end
end
