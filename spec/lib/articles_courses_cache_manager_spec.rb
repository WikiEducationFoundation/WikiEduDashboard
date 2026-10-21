# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/articles_courses_cache_manager"

describe ArticlesCoursesCacheManager do
  let(:article) { create(:article) }
  let(:course) { create(:course, start: '2024-06-16', end: '2024-08-16') }

  describe '#update_caches_from_timeslices' do
    let(:articles_course) { create(:articles_course, article:, course:) }

    before do
      articles_course
      create(:article_course_timeslice, article:, course:,
             start: '2024-07-06', end: '2024-07-07',
             character_sum: 9000, references_count: 4, user_ids: [2, 3],
             first_revision: '2024-07-06 03:45:04')
      create(:article_course_timeslice, article:, course:,
             start: '2024-07-07', end: '2024-07-08',
             character_sum: 12, references_count: 5, user_ids: [2, 4],
             new_article: true, first_revision: '2024-07-07 20:10:24')
      # Empty timeslice, which should not count towards the stats.
      create(:article_course_timeslice, article:, course:,
             start: '2024-06-25', end: '2024-06-26',
             character_sum: 0, references_count: 0, user_ids: nil, first_revision: nil)

      described_class.new(ArticlesCourses.where(course:)).update_caches_from_timeslices
    end

    it 'sums the character sum of every timeslice' do
      expect(articles_course.reload.character_sum).to eq(9012)
    end

    it 'sums the references count of every timeslice' do
      expect(articles_course.reload.references_count).to eq(9)
    end

    it 'merges the user ids of every timeslice, without duplicates' do
      expect(articles_course.reload.user_ids).to match_array([2, 3, 4])
    end

    it 'does not pick up nil user ids from empty timeslices' do
      expect(articles_course.reload.user_ids).not_to include(nil)
    end

    it 'marks the article as new when any timeslice is new' do
      expect(articles_course.reload.new_article).to be true
    end

    it 'takes the earliest first revision' do
      expect(articles_course.reload.first_revision).to eq('2024-07-06 03:45:04')
    end
  end

  describe '#update_caches_from_timeslices with no timeslices' do
    let(:articles_course) do
      create(:articles_course, article:, course:, character_sum: 999, references_count: 5,
             user_ids: [7], new_article: true, first_revision: '2024-07-01')
    end

    before do
      articles_course
      described_class.new(ArticlesCourses.where(course:)).update_caches_from_timeslices
    end

    it 'resets the cached values' do
      expect(articles_course.reload).to have_attributes(character_sum: 0, references_count: 0,
                                                        user_ids: [], new_article: false,
                                                        first_revision: nil)
    end
  end

  describe '#update_caches_from_timeslices for two courses sharing an article' do
    let(:other_course) do
      create(:course, slug: 'Other/Course', start: '2024-06-16', end: '2024-08-16')
    end

    before do
      create(:articles_course, article:, course:)
      create(:articles_course, article:, course: other_course)
      create(:article_course_timeslice, article:, course:,
             start: '2024-07-11', end: '2024-07-12', character_sum: 500)
      create(:article_course_timeslice, article:, course: other_course,
             start: '2024-07-11', end: '2024-07-12', character_sum: 900)

      described_class.new(ArticlesCourses.all).update_caches_from_timeslices
    end

    it 'gives the course the totals of its own timeslices' do
      expect(ArticlesCourses.find_by(course:).character_sum).to eq(500)
    end

    it 'gives the other course the totals of its own timeslices' do
      expect(ArticlesCourses.find_by(course: other_course).character_sum).to eq(900)
    end
  end

  describe '#update_caches_from_timeslices across several batches' do
    let(:article2) { create(:article, title: 'Second Article') }
    let(:article3) { create(:article, title: 'Third Article') }

    before do
      stub_const('ArticlesCoursesCacheManager::BATCH_SIZE', 2)
      [article, article2, article3].each_with_index do |current_article, index|
        create(:articles_course, article: current_article, course:)
        create(:article_course_timeslice, article: current_article, course:,
               start: '2024-07-11', end: '2024-07-12', character_sum: (index + 1) * 100)
      end

      described_class.new(ArticlesCourses.where(course:)).update_caches_from_timeslices
    end

    it 'updates the records of every batch' do
      sums = ArticlesCourses.where(course:).pluck(:article_id, :character_sum).to_h
      expect(sums).to eq(article.id => 100, article2.id => 200, article3.id => 300)
    end
  end
end
