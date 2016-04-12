require 'rails_helper'

describe RevisionsController do
  describe '#index' do
    let(:course_start) { Date.new(2015, 1, 1) }
    let(:course_end) { Date.new(2016, 1, 1) }
    let!(:course) { create(:course, start: '2015-01-01', end: '2016-01-01') }
    let!(:user) { create(:user) }
    let!(:user2) { create(:user, id: 2) }
    let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let!(:courses_user2) { create(:courses_user, course_id: course.id, user_id: 2) }

    let!(:article) { create(:article, mw_page_id: 1) }
    let!(:course_revisions) do
      (1..5).map do |i|
        create(:revision, article_id: article.id, mw_page_id: 1,
                          user_id: user.id, mw_rev_id: i, date: course_end + 6.hours)
      end
    end
    let!(:non_course_revisions) do
      (6..10).map do |i|
        create(:revision, article_id: article.id, mw_page_id: 1,
                          user_id: user.id, mw_rev_id: i, date: course_end + 1.day)
      end
    end

    let!(:non_user_revisions) do
      (11..15).map do |i|
        create(:revision, article_id: article.id, mw_page_id: 1,
                          user_id: 2, mw_rev_id: i, date: course_end - 1.day)
      end
    end
    let(:params) { { course_id: course.id, user_id: user.id, format: 'json' } }

    it 'returns revisions that happened during the course' do
      get :index, params
      course_revisions.each do |revision|
        expect(assigns(:revisions)).to include(revision)
      end
    end

    it 'does not return revisions that happened after the last day of the course' do
      get :index, params
      non_course_revisions.each do |revision|
        expect(assigns(:revisions)).not_to include(revision)
      end
    end

    it 'does not return course revisions by other users' do
      get :index, params
      non_user_revisions.each do |revision|
        expect(assigns(:revisions)).not_to include(revision)
      end
    end
  end
end
