# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

describe ArticlesCoursesCleanerTimeslice do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:course) { create(:course, start: '2024-01-01', end: '2024-04-20') }
  let(:manager) { TimesliceManager.new(course) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: wikidata) }
  let(:article3) { create(:article, wiki: wikidata) }

  describe '.clean_articles_courses_for_wiki_ids' do
    before do
      stub_wiki_validation
      create(:articles_course, course:, article: article1)
      create(:articles_course, course:, article: article2)
      create(:articles_course, course:, article: article3)
    end

    it 'removes ArticlesCourses that belong to a deleted wiki' do
      expect(course.articles_courses.size).to eq(3)
      # Wikidata courses_wikis record was deleted
      described_class.clean_articles_courses_for_wiki_ids(course, wikidata.id)
      expect(course.articles_courses.size).to eq(1)
    end
  end

  describe '.clean_articles_courses_for_user_ids' do
    before do
      stub_wiki_validation
      create(:articles_course, course:, article: article1, user_ids: [1, 45])
      create(:articles_course, course:, article: article3, user_ids: [47, 45, 5])
      create(:articles_course, course:, article: article2, user_ids: [455])
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: article1.id, course_id: course.id },
         { article_id: article2.id, course_id: course.id },
         { article_id: article3.id, course_id: course.id }]
      )
    end

    it 'removes ArticlesCourses and their timeslices that were edited only by removed users' do
      expect(course.article_course_timeslices.size).to eq(342)
      expect(course.articles_courses.size).to eq(3)
      # User ids 5, 45 and 47 were deleted
      described_class.clean_articles_courses_for_user_ids(course, [5, 45, 47])
      expect(course.article_course_timeslices.size).to eq(228)
      expect(course.articles_courses.size).to eq(2)
      expect(course.articles_courses.first.user_ids).to eq([1, 45])
      expect(course.articles_courses.second.user_ids).to eq([455])
    end
  end
end
