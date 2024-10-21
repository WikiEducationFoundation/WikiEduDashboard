# frozen_string_literal: true

require 'rails_helper'

describe CourseWikiUpdater do
  let(:course) { create(:course, start: '2018-11-24', end: '2018-11-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:updater) { described_class.new(course).run }
  let(:user) { create(:user, username: 'Ragesoss') }
  let(:manager) { TimesliceManager.new(course) }
  let(:wikidata_article) { create(:article, wiki: wikidata) }
  let(:article) { create(:article, wiki: enwiki) }

  context 'when some previous wiki was removed' do
    before do
      stub_wiki_validation
      # Add a user
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user:, role: 0)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      # Add articles courses and timeslices manually
      create(:articles_course, course:, article: wikidata_article)
      create(:articles_course, course:, article:)
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: wikidata_article.id, course_id: course.id },
         { article_id: article.id, course_id: course.id }]
      )
      # Create course wiki timeslices manually for wikidata
      course.wikis << wikidata
      manager.create_timeslices_for_new_course_wiki_records([wikidata])
      course.wikis.delete(wikidata)
    end

    it 'removes existing wiki timeslices' do
      # There is one user, two articles and two wikis
      expect(course.course_wiki_timeslices.count).to eq(14)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(7)
      expect(course.article_course_timeslices.count).to eq(7)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end

  context 'when a new wiki was added' do
    before do
      stub_wiki_validation
      # Add a user
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user:, role: 0)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      # Add articles courses and timeslices manually
      create(:articles_course, course:, article:)
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: article.id, course_id: course.id }]
      )
    end

    it 'adds wiki timeslices' do
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(7)
      expect(course.article_course_timeslices.count).to eq(7)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)

      course.wikis << wikidata
      described_class.new(course).run
      # There is one user, one article and two wikis
      expect(course.course_wiki_timeslices.count).to eq(14)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(7)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end
end
