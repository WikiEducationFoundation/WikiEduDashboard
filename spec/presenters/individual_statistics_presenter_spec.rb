# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/individual_statistics_presenter'

describe IndividualStatisticsPresenter do
  describe 'individual_article_views' do
    let(:course1) { create(:course) }
    let(:course2) { create(:course, slug: 'foo/2') }
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    subject { described_class.new(user: user) }

    context 'when a user is in two courses that overlap' do
      before do
        create(:courses_user, user_id: user.id, course_id: course1.id)
        create(:courses_user, user_id: user.id, course_id: course2.id)
        create(:revision, views: 100, user_id: user.id, article_id: article.id,
                          date: course1.start + 1.minute)
        ArticlesCourses.update_from_course(course1)
        ArticlesCourses.update_from_course(course2)
      end
      it 'does\'t double count the same article in multiple courses' do
        expect(course1.revisions.count).to eq(1)
        expect(course2.revisions.count).to eq(1)
        expect(subject.individual_article_views).to eq(100)
      end
    end

    context 'when there are revisions made before the course started ' do
      before do
        create(:courses_user, user_id: user.id, course_id: course1.id)
        create(:courses_user, user_id: user.id, course_id: course2.id)
        create(:revision, views: 100, user_id: user.id, article_id: article.id,
                          date: course1.start + 1.minute)
        create(:revision, views: 150, user_id: user.id, article_id: article.id,
                          date: course1.start - 1.minute)
        ArticlesCourses.update_from_course(course1)
        ArticlesCourses.update_from_course(course2)
      end
      it 'only counts views for revisions that happen during a course' do
        expect(course1.revisions.count).to eq(1)
        expect(course2.revisions.count).to eq(1)
        expect(subject.individual_article_views).to eq(100)
      end
    end
  end
end
