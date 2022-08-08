# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/individual_statistics_presenter'

describe IndividualStatisticsPresenter do
  describe 'individual_article_views' do
    subject { described_class.new(user:) }

    let(:course1) { create(:course, start: 1.year.ago, end: 1.day.ago) }
    let(:course2) { create(:course, slug: 'foo/2', start: 1.year.ago, end: 1.day.ago) }
    let(:user) { create(:user) }
    let(:article) { create(:article, average_views: 10) }
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

    context 'when a user is in two courses that overlap' do
      before do
        create(:commons_upload, user_id: user.id, usage_count: 1,
                                uploaded_at: course1.start + 1.minute)
        create(:revision, views: 100, user_id: user.id, article_id: article.id,
                          date: course1.start + 1.minute, new_article: true, characters: 100,
                          features: {
                            refs_tags_key => 22
                          })
        create(:courses_user, user_id: user.id, course_id: course1.id)
        create(:courses_user, user_id: user.id, course_id: course2.id)
        create(:articles_course, article_id: article.id, course_id: course1.id)
        create(:articles_course, article_id: article.id, course_id: course2.id)
        ArticlesCourses.update_from_course(course1)
        ArticlesCourses.update_from_course(course2)
        Course.update_all_caches
        CoursesUsers.update_all_caches(CoursesUsers.all)
      end

      it 'does\'t double count the same articles or revisions in multiple courses' do
        expect(course1.revisions.count).to eq(1)
        expect(course2.revisions.count).to eq(1)
        expect(subject.individual_article_views).to be > 3600
        expect(subject.individual_character_count).to eq(100)
        expect(subject.individual_references_count).to eq(22)
        expect(subject.individual_article_count).to eq(1)
        expect(subject.individual_articles_created).to eq(1)
      end

      it 'does not double count upload stats' do
        expect(course1.uploads.count).to eq(1)
        expect(course2.uploads.count).to eq(1)
        expect(subject.individual_upload_count).to eq(1)
        expect(subject.individual_upload_usage_count).to eq(1)
      end
    end

    context 'when there are revisions made before the course started' do
      before do
        create(:courses_user, user_id: user.id, course_id: course1.id)
        create(:courses_user, user_id: user.id, course_id: course2.id)
        create(:revision, views: 100, user_id: user.id, article_id: article.id,
                          date: course1.start + 1.minute)
        create(:revision, views: 150, user_id: user.id, article_id: article.id,
                          date: course1.start - 1.year)
        ArticlesCourses.update_from_course(course1)
        ArticlesCourses.update_from_course(course2)
      end

      it 'only counts views for revisions that happen during a course' do
        expect(course1.revisions.count).to eq(1)
        expect(course2.revisions.count).to eq(1)
        expect(subject.individual_article_views).to be < 3800
      end
    end
  end
end
