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

describe ArticlesCourses, type: :model do
  let(:article) { create(:article, average_views: 1234) }
  let(:article_id) { article.id }
  let(:user) { create(:user, id: 1) }
  let(:user_id) { user.id }
  let(:course) { create(:course, start: '2024-06-16', end: '2024-08-16') }
  let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

  before do
    travel_to Date.new(2024, 7, 16)
  end

  after do
    travel_back
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
             user_ids: [2, 3],
             first_revision: '2024-07-06 03:45:04')

      create(:article_course_timeslice,
             article:,
             course:,
             start: '2024-07-07',
             end: '2024-07-08',
             character_sum: 12,
             references_count: 5,
             user_ids: [2, user.id],
             new_article: true,
             first_revision: '2024-07-07 20:10:24')

      # Empty timeslice, which should not count towards stats.
      create(:article_course_timeslice,
             article:,
             course:,
             start: '2024-06-25',
             end: '2024-06-26',
             character_sum: 0,
             references_count: 0,
             user_ids: nil,
             first_revision: nil)

      # Run the cache update again with an existing revision.
      described_class.update_all_caches_from_timeslices(described_class.all)

      # Fetch the updated ArticlesCourses entry
      article_course = described_class.first

      expect(article_course.character_sum).to eq(9012)
      expect(article_course.references_count).to eq(9)
      expect(article_course.user_ids).to eq([2, 3, user.id])
      expect(article_course.view_count).to eq(0)
      expect(article_course.new_article).to be true
      expect(article_course.first_revision).to eq('2024-07-06 03:45:04')
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
      array_revisions << build(:revision_on_memory, article_id:, user_id:, date: '2024-07-07',
                        system: true, new_article: true, scoped: true)
      array_revisions << build(:revision_on_memory, article_id:, user_id:,
                        date: '2024-07-06 20:05:10', system: true, new_article: true, scoped: true)
      array_revisions << build(:revision_on_memory, article_id:, user_id:,
                        date: '2024-07-06 20:06:11', system: true, new_article: true, scoped: true)
      array_revisions << build(:revision_on_memory, article_id:, user_id:,
                        date: '2024-07-08 20:03:01', system: true, new_article: true, scoped: true)
      array_revisions << build(:revision_on_memory, article_id: article3.id, user_id:,
                        date: '2024-07-07', system: true, new_article: true, scoped: true)
      # revision for a non-tracked wiki
      array_revisions << build(:revision_on_memory, article_id: article2.id, user_id:,
                        date: '2024-07-06')
      # revision for a non-tracked namespace
      array_revisions << build(:revision_on_memory, article_id: talk_page.id, user_id:,
                        date: '2024-07-07')
    end

    it 'creates new ArticlesCourses records from course revisions' do
      expect(described_class.count).to eq(0)
      described_class.update_from_course_revisions(course, array_revisions)
      expect(described_class.count).to eq(2)
    end
  end
end
