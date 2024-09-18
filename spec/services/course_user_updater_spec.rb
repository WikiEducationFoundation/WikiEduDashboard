# frozen_string_literal: true

require 'rails_helper'

describe CourseUserUpdater do
  let(:course) { create(:course, start: '2018-11-24', end: '2018-11-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:updater) { described_class.new(course).run }
  let(:user1) { create(:user, username: 'Ragesoss') }
  let(:user2) { create(:user, username: 'Wikimedian') }
  let(:manager) { TimesliceManager.new(course) }
  let(:wikidata_article) { create(:article, wiki: wikidata) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: enwiki) }

  context 'when some course user was removed' do
    before do
      stub_wiki_validation
      # Add two users
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user: user1, role: 0)
      JoinCourse.new(course:, user: user2, role: 0)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      # Add articles courses and timeslices manually
      create(:articles_course, course:, article: article1, user_ids: [user1.id])
      create(:articles_course, course:, article: article2, user_ids: [user1.id, user2.id])
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: article1.id, course_id: course.id },
         { article_id: article2.id, course_id: course.id }]
      )
      # Update articles courses timeslices
      ArticleCourseTimeslice.where(course:, article: article1).first.update(user_ids: [user1.id])
      timeslices = ArticleCourseTimeslice.where(course:, article: article2)
      timeslices.first.update(user_ids: [user1.id, user2.id])
      timeslices.second.update(user_ids: [user2.id])
      timeslices.third.update(user_ids: [user1.id])
      # Delete course user
      CoursesUsers.find_by(course:, user: user1).delete
    end

    it 'removes course user wiki timeslices and updates course wiki timeslices' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(10)
      expect(course.course_user_wiki_timeslices.count).to eq(20)
      expect(course.article_course_timeslices.count).to eq(20)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(10)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(10)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end
end
