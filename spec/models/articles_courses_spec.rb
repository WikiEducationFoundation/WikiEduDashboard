# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  article_id    :integer
#  course_id     :integer
#  view_count    :bigint(8)        default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticlesCourses, type: :model do
  let(:article) { create(:article, average_views: 1234) }
  let(:user) { create(:user) }
  let(:course) { create(:course, start: 1.month.ago, end: 1.month.from_now) }
  let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

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
             date: 1.day.ago,
             characters: 9000,
             features: {
               refs_tags_key => 22
             },
             new_article: true)

      # Deleted revision, which should not count towards stats.
      create(:revision,
             user:,
             article:,
             date: Time.zone.today,
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
      create(:revision, article:, user:, date: 1.week.ago, new_article: true)

      described_class.update_all_caches(described_class.all)
      article_course = described_class.first

      expect(article_course.new_article).to be true
    end

    it 'updates new_article for a system and new_article revision by another editor' do
      create(:revision, article:, user: instructor, date: 1.week.ago,
                        system: true, new_article: true)

      described_class.update_all_caches(described_class.all)
      article_course = described_class.first

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
end
