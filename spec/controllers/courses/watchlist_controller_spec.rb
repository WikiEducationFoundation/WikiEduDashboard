# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Courses::WatchlistController, type: :controller do
  let(:course) { create(:course) }
  let(:user) { create(:admin) }
  let(:wiki) { course.home_wiki }
  let(:array_of_users) { [%w[User:John User:Smith]] }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:find_course_by_slug).and_return(course)
    allow(course).to receive(:home_wiki).and_return(wiki)
    allow_any_instance_of(CoursesUsers).to receive(:user_page).with(course.students).and_return(array_of_users)
  end

  describe 'POST #add_to_watchlist' do
    it 'watches the user pages for the students' do
      puts wiki.inspect
      watchlist_edits = instance_double(WatchlistEdits)
      expect(WatchlistEdits).to receive(:new).with(wiki, user).and_return(watchlist_edits)
      expect(watchlist_edits).to receive(:watch_userpages).with(array_of_users)

      post :add_to_watchlist, params: { slug: course.slug }
      expect(response).to have_http_status(:success)
    end
  end
end
