# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id               :integer          not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  article_id       :integer
#  course_id        :integer
#  view_count       :bigint           default(0)
#  character_sum    :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  references_count :integer          default(0)
#  tracked          :boolean          default(TRUE)
#  user_ids         :text(65535)
#  first_revision   :datetime
#

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticlesCourses, type: :model do
  let(:article) { create(:article, average_views: 1234) }
  let(:user) { create(:user, id: 1) }
  let(:course) { create(:course, start: '2024-06-16', end: '2024-08-16') }
  let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

  before do
    travel_to Date.new(2024, 7, 16)
  end

  describe '.update_all_caches' do
    let(:instructor) { create(:instructor) }

    before do
      # Make an ArticlesCourses record
      create(:articles_course, article:, course:)
      # Add user to course
      create(:courses_user, course:, user:)
    end

    it 'updates data for article-course relationships' do
      # Run a cache update without any revisions.
      described_class.update_all_caches(described_class.all)

      # Add a revision.
      create(:revision,
             user:,
             article:,
             date: '2024-07-15',
             characters: 9000,
             features: {
               refs_tags_key => 22
             },
             new_article: true)

      # Deleted revision, which should not count towards stats.
      create(:revision,
             user:,
             article:,
             date: '2024-07-16',
             characters: 9001,
             deleted: true)

      # Run the cache update again with an existing revision.
      described_class.update_all_caches(described_class.all)

      # Fetch the created ArticlesCourses entry
      article_course = described_class.first

      expect(article_course.view_count).to eq(1234)
      expect(article_course.new_article).to be true
      expect(article_course.references_count).to eq(22)
      expect(article_course.character_sum).to eq(9000)
    end

    it 'updates new_article for a new_article revision by student' do
      create(:revision, article:, user:, date: '2024-07-07', new_article: true)

      described_class.update_all_caches(described_class.all)
      article_course = described_class.first

      expect(article_course.new_article).to be true
    end

    it 'updates new_article for a system and new_article revision by another editor' do
      create(:revision, article:, user: instructor, date: '2024-07-07',
                        system: true, new_article: true)

      described_class.update_all_caches(described_class.all)
      article_course = described_class.first

      expect(article_course.new_article).to be true
    end
  end

  describe '.update_all_caches_from_timeslices' do
    let(:instructor) { create(:instructor) }

    before do
      # Make an ArticlesCourses record
      create(:articles_course, id: 456, article:, course:)
      # Add user to course
      create(:courses_user, course:, user:)
    end

    it 'updates data for article-course relationships' do
      # Run a cache update without any timeslices.
      described_class.update_all_caches_from_timeslices(described_class.all)

      # Add two timeslices.
      create(:article_course_timeslice,
             article:,
             course:,
             start: '2024-07-06',
             end: '2024-07-07',
             character_sum: 9000,
             references_count: 4,
             user_ids: [2, 3])

      create(:article_course_timeslice,
             article:,
             course:,
             start: '2024-07-07',
             end: '2024-07-08',
             character_sum: 12,
             references_count: 5,
             user_ids: [2, user.id],
             new_article: true)

      # Empty timeslice, which should not count towards stats.
      create(:article_course_timeslice,
             article:,
             course:,
             start: '2024-06-25',
             end: '2024-06-26',
             character_sum: 0,
             references_count: 0,
             user_ids: nil)

      # Run the cache update again with an existing revision.
      described_class.update_all_caches_from_timeslices(described_class.all)

      # Fetch the updated ArticlesCourses entry
      article_course = described_class.first

      expect(article_course.character_sum).to eq(9012)
      expect(article_course.references_count).to eq(9)
      expect(article_course.user_ids).to eq([2, 3, user.id])
      # expect(article_course.view_count).to eq(12340)
      expect(article_course.new_article).to be true
    end
  end

  describe '.update_from_course' do
    let(:course) { create(:course, start: 1.year.ago, end: 1.day.ago) }
    let(:another_course) { create(:course, slug: 'something else') }
    let(:user) { create(:user) }
    let(:article) { create(:article, namespace: 0) }
    let(:article2) { create(:article, title: 'Second Article', namespace: 0) }
    let(:talk_page) { create(:article, title: 'Talk page', namespace: 1) }

    before do
      create(:courses_user, user:, course:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:revision, article:, user:, date: 1.week.ago,
                        system: true, new_article: true)
      create(:revision, article:, user:, date: 6.days.ago)
      # old revision before course
      create(:revision, article: article2, user:, date: 2.years.ago)
      create(:revision, article: talk_page, user:, date: 1.week.ago)
    end

    it 'creates new ArticlesCourses records from course revisions' do
      described_class.update_from_course(Course.last)
      expect(described_class.count).to eq(1)
      # Should be counted as new even though the first edit was a system edit.
      described_class.last.update_cache
      expect(described_class.last.new_article).to eq(true)
    end

    it 'destroys ArticlesCourses that do not correspond to course revisions' do
      create(:articles_course, id: 500, article: article2, course:)
      create(:articles_course, id: 501, article: article2, course: another_course)
      described_class.update_from_course(course)
      expect(described_class.exists?(500)).to eq(false)
      # only destroys for the course specified, not other recoreds that also
      # don't correspond to their own course.
      expect(described_class.exists?(501)).to eq(true)
      described_class.update_from_course(another_course)
      expect(described_class.exists?(501)).to eq(false)
    end
  end

  describe '.update_from_course_revisions' do
    let(:article2) { create(:article, title: 'Second Article', namespace: 0, wiki_id: 2) }
    let(:article3) { create(:article, title: 'Third Article', namespace: 0) }
    let(:talk_page) { create(:article, title: 'Talk page', namespace: 1) }
    let(:array_revisions) { [] }

    before do
      create(:courses_user, user:, course:,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      array_revisions << build(:revision, article:, user:, date: '2024-07-07',
                        system: true, new_article: true)
      array_revisions << build(:revision, article:, user:, date: '2024-07-06 20:05:10',
                        system: true, new_article: true)
      array_revisions << build(:revision, article:, user:, date: '2024-07-06 20:06:11',
                        system: true, new_article: true)
      array_revisions << build(:revision, article:, user:, date: '2024-07-08 20:03:01',
                        system: true, new_article: true)
      array_revisions << build(:revision, article: article3, user:, date: '2024-07-07',
                        system: true, new_article: true)
      # revision for a non-tracked wiki
      array_revisions << build(:revision, article: article2, user:, date: '2024-07-06')
      # revision for a non-tracked namespace
      array_revisions << build(:revision, article: talk_page, user:, date: '2024-07-07')
    end

    it 'creates new ArticlesCourses records from course revisions' do
      expect(described_class.count).to eq(0)
      described_class.update_from_course_revisions(course, array_revisions)
      expect(described_class.count).to eq(2)
      expect(described_class.first.first_revision).to eq('2024-07-06 20:05:10')
      # 62 days from course start up to course end x 2 articles courses
      expect(described_class.first.article_course_timeslices.count).to eq(62)
      expect(described_class.second.article_course_timeslices.count).to eq(62)
    end
  end
end
