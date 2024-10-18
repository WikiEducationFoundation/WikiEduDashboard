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
      expect(course.article_course_timeslices.size).to eq(333)
      expect(course.articles_courses.size).to eq(3)
      # User ids 5, 45 and 47 were deleted
      described_class.clean_articles_courses_for_user_ids(course, [5, 45, 47])
      expect(course.article_course_timeslices.size).to eq(222)
      expect(course.articles_courses.size).to eq(2)
      expect(course.articles_courses.first.user_ids).to eq([1, 45])
      expect(course.articles_courses.second.user_ids).to eq([455])
    end
  end

  describe '.clean_articles_courses_prior_to_course_start' do
    before do
      stub_wiki_validation
      create(:articles_course, course:, article: article1, user_ids: [1])
      create(:articles_course, course:, article: article2, user_ids: [47])
      create(:articles_course, course:, article: article3, user_ids: [455])
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: article1.id, course_id: course.id },
         { article_id: article2.id, course_id: course.id },
         { article_id: article3.id, course_id: course.id }]
      )
      # Course start date is updated
      course.update(start: '2024-01-10')

      # Article 1 was only edited before the new start date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article1.id)
                                        .where(start: '2024-01-02'.to_datetime)
                                        .first
      timeslice.update(user_ids: [1])
      # Article 2 was edited before and after the new start date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article2.id)
                                        .where(start: '2024-01-02'.to_datetime)
                                        .first
      timeslice.update(user_ids: [47])
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article2.id)
                                        .where(start: '2024-02-15'.to_datetime)
                                        .first
      timeslice.update(user_ids: [47])
      # Article 3 was only edited after the new start date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article3.id)
                                        .where(start: '2024-02-18'.to_datetime)
                                        .first
      timeslice.update(user_ids: [455])
    end

    it 'removes ArticlesCourses and timeslices that do not belong to the course anymore' do
      expect(course.article_course_timeslices.size).to eq(333)
      expect(course.articles_courses.size).to eq(3)
      # Clean articles courses
      described_class.clean_articles_courses_prior_to_course_start(course)

      # Timeslices for article 1 were deleted
      expect(course.article_course_timeslices.where(article_id: article1.id).size).to eq(0)
      # Timeslices prior to the new course start date were deleted
      expect(course.article_course_timeslices.where('end <= ?', course.start).size).to eq(0)
      expect(course.article_course_timeslices.size).to eq(204)
      # Article 1 was deleted
      expect(course.articles_courses.size).to eq(2)
      expect(course.articles_courses.first.article_id).to eq(article2.id)
      expect(course.articles_courses.second.article_id).to eq(article3.id)
    end
  end

  describe '.clean_articles_courses_after_course_end' do
    before do
      stub_wiki_validation
      create(:articles_course, course:, article: article1, user_ids: [1])
      create(:articles_course, course:, article: article2, user_ids: [47])
      create(:articles_course, course:, article: article3, user_ids: [455])
      manager.create_timeslices_for_new_article_course_records(
        [{ article_id: article1.id, course_id: course.id },
         { article_id: article2.id, course_id: course.id },
         { article_id: article3.id, course_id: course.id }]
      )
      # Course end date is updated
      course.update(end: '2024-04-10')

      # Article 1 was only edited after the new end date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article1.id)
                                        .where(start: '2024-04-15'.to_datetime)
                                        .first
      timeslice.update(user_ids: [1])
      # Article 2 was edited before and after the new end date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article2.id)
                                        .where(start: '2024-01-02'.to_datetime)
                                        .first
      timeslice.update(user_ids: [47])
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article2.id)
                                        .where(start: '2024-04-16'.to_datetime)
                                        .first
      timeslice.update(user_ids: [47])
      # Article 3 was only edited after the new end date
      timeslice = ArticleCourseTimeslice.where(course:)
                                        .where(article_id: article3.id)
                                        .where(start: '2024-02-18'.to_datetime)
                                        .first
      timeslice.update(user_ids: [455])
    end

    it 'removes ArticlesCourses and timeslices that do not belong to the course anymore' do
      expect(course.article_course_timeslices.size).to eq(333)
      expect(course.articles_courses.size).to eq(3)
      # Clean articles courses
      described_class.clean_articles_courses_after_course_end(course)

      # Timeslices for article 1 were deleted
      expect(course.article_course_timeslices.where(article_id: article1.id).size).to eq(0)
      # Timeslices after the new course end date were deleted
      expect(course.article_course_timeslices.where('start > ?', course.end).size).to eq(0)
      expect(course.article_course_timeslices.size).to eq(202)
      # Article 1 was deleted
      expect(course.articles_courses.size).to eq(2)
      expect(course.articles_courses.first.article_id).to eq(article2.id)
      expect(course.articles_courses.second.article_id).to eq(article3.id)
    end
  end
end
