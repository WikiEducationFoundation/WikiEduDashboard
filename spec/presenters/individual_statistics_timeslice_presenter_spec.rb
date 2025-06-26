# frozen_string_literal: true

require 'rails_helper'

describe IndividualStatisticsTimeslicePresenter do
  describe 'individual_article_views' do
    subject { described_class.new(user:) }

    let(:start) { 1.year.ago.beginning_of_day }
    let(:course_end) { 1.day.ago.end_of_day }
    let(:course1) { create(:course, start:, end: course_end) }
    let(:course2) { create(:course, slug: 'foo/2', start:, end: course_end) }
    let(:user) { create(:user) }
    let(:article) { create(:article, average_views: 10) }
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }
    let(:array_revisions) { [] }

    context 'when a user is in two courses that overlap' do
      before do
        create(:commons_upload, user_id: user.id, usage_count: 1,
                                uploaded_at: start + 1.minute)
        array_revisions << build(:revision_on_memory, user_id: user.id, article_id: article.id,
                          date: start + 1.minute, new_article: true, characters: 100,
                          features: {
                            refs_tags_key => 22
                          }, scoped: true)
        create(:courses_user, user_id: user.id, course_id: course1.id)
        create(:courses_user, user_id: user.id, course_id: course2.id)
        create(:articles_course, article_id: article.id, course_id: course1.id)
        create(:articles_course, article_id: article.id, course_id: course2.id)
        ArticlesCourses.update_from_course_revisions(course1, array_revisions)
        ArticlesCourses.update_from_course_revisions(course2, array_revisions)
        TimesliceManager.new(course1).create_timeslices_for_new_course_wiki_records(course1.wikis)
        TimesliceManager.new(course2).create_timeslices_for_new_course_wiki_records(course2.wikis)

        revision_data = { start:, end: start + 1.day - 1.second,
                          revisions: array_revisions }
        CourseUserWikiTimeslice.update_course_user_wiki_timeslices(course1, user.id,
                                                                   course1.wikis.first,
                                                                   revision_data)
        CourseUserWikiTimeslice.update_course_user_wiki_timeslices(course2, user.id,
                                                                   course2.wikis.first,
                                                                   revision_data)
        CoursesUsers.update_all_caches_from_timeslices(CoursesUsers.all)

        ArticleCourseTimeslice.update_article_course_timeslices(course1, article.id,
                                                                revision_data)
        ArticleCourseTimeslice.update_article_course_timeslices(course2, article.id,
                                                                revision_data)
        ArticlesCourses.update_all_caches_from_timeslices(ArticlesCourses.all)
        course1.update_cache_from_timeslices
        course2.update_cache_from_timeslices
      end

      it 'does\'t double count the same articles in multiple courses' do
        expect(course1.articles_courses.count).to eq(1)
        expect(course2.articles_courses.count).to eq(1)

        # double count character count and references
        expect(subject.individual_character_count).to eq(200)
        expect(subject.individual_references_count).to eq(44)

        # does not double count article count
        expect(subject.individual_article_count).to eq(1)
      end

      it 'does not double count upload stats' do
        expect(course1.uploads.count).to eq(1)
        expect(course2.uploads.count).to eq(1)
        expect(subject.individual_upload_count).to eq(1)
        expect(subject.individual_upload_usage_count).to eq(1)
      end
    end
  end
end
