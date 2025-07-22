# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Courses::WatchlistController, type: :controller do
  let(:course) { create(:course) }
  let(:user) { create(:admin) }
  let(:wiki) { course.home_wiki }
  let(:users) { [create(:user, username: 'John'), create(:user, username: 'Smith')] }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:find_course_by_slug).and_return(course)
    allow(course).to receive(:home_wiki).and_return(wiki)
    allow(course).to receive(:students).and_return(users)
    allow(users).to receive(:map).and_return(users.map(&:user_page))
  end

  describe 'POST #add_to_watchlist' do
    it 'watches the user pages for the students' do
      watchlist_edits = instance_double(WatchlistEdits)
      expect(WatchlistEdits).to receive(:new).with(wiki, user).and_return(watchlist_edits)
      expect(watchlist_edits).to receive(:watch_userpages).with(users.map(&:user_page))

      post :add_to_watchlist, params: { slug: course.slug }
      expect(response).to have_http_status(:success)
    end
  end
end
