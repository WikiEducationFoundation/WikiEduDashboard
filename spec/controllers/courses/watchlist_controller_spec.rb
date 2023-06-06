# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Courses::WatchlistController, type: :controller do
  describe 'POST #add_to_watchlist' do
    let(:course) { create(:course) }
    let(:user) { create(:admin) }
    let(:student_names) { %w[Student1 Student2] }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:find_course_by_slug).and_return(course)
      courses_users = instance_double(CoursesUsers)
      allow(CoursesUsers).to receive(:new).and_return(courses_users)
      allow(courses_users).to receive(:user_page).and_return(student_names)
      allow_any_instance_of(WatchlistEdits).to receive(:oauth_credentials_valid?).and_return(true)
    end

    it 'calls WatchlistEdits with the correct arguments and checks OAuth credentials' do
      expect_any_instance_of(described_class)
        .to receive(:find_course_by_slug)
        .with(course.slug)
        .and_return(course)
      courses_users = instance_double(CoursesUsers)
      allow(CoursesUsers).to receive(:new).and_return(courses_users)
      allow(courses_users).to receive(:user_page).with(course.students).and_return(student_names)
      expect(WatchlistEdits).to receive(:new).with(course.home_wiki,
                                                   student_names).and_call_original
      expect_any_instance_of(WatchlistEdits).to receive(:oauth_credentials_valid?).with(user)

      post :add_to_watchlist, params: { slug: course.slug }

      expect(response).to be_successful
    end
  end
end
