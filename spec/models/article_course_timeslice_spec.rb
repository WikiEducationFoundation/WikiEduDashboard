# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  article_id       :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  user_ids         :text(65535)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  first_revision   :datetime
#

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticleCourseTimeslice, type: :model do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:start) { 1.month.ago.beginning_of_day }
  let(:course) { create(:course, start:, end: 1.month.from_now.beginning_of_day) }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article_course) { create(:articles_course, article:, course:) }
  let(:revision1) do
    build(:revision, article:,
           characters: 123,
           features: { 'num_ref' => 4 },
           features_previous: { 'num_ref' => 0 },
           user_id: 25,
           date: start + 1.hour,
           new_article: true)
  end
  let(:revision2) do
    build(:revision, article:,
           characters: -65,
           features: { 'num_ref' => 1 },
           features_previous: { 'num_ref' => 2 },
           user_id: 1,
           date: start + 10.hours)
  end
  let(:revision3) do
    build(:revision, article:,
           characters: 225,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: 25,
           date: start + 12.hours)
  end
  let(:revision4) do
    build(:revision, article:,
            characters: 34,
            deleted: true, # deleted revision
            features: { 'num_ref' => 2 },
            features_previous: { 'num_ref' => 0 },
            user_id: 6,
            date: start + 16.hours)
  end
  let(:revision5) do
    build(:revision, article:,
           characters: 120,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: 25,
           date: start + 12.hours,
           system: true) # revision made automatically
  end
  let(:revisions) { [revision1, revision2, revision3, revision4, revision5] }
  let(:article_course_timeslice) do
    create(:article_course_timeslice,
           article:,
           course:,
           character_sum: 100,
           references_count: 3,
           user_ids: [2, 4])
  end
  let(:subject) { article_course_timeslice.update_cache_from_revisions revisions }

  describe '.update_article_course_timeslices' do
    before do
      revisions << build(:revision, article:, user_id: 1, date: start + 26.hours)
      revisions << build(:revision, article:, user_id: 3, date: start + 50.hours)
      revisions << build(:revision, article:, user_id: 7, date: start + 51.hours)

      create(:course_wiki_timeslice, course:, wiki:, start:, end: start + 1.day)
      create(:course_wiki_timeslice, course:, wiki:, start: start + 1.day,
             end: start + 2.days)
      create(:course_wiki_timeslice, course:, wiki:, start: start + 2.days,
            end: start + 3.days)
    end

    it 'creates the right article timeslices based on the revisions' do
      article_course_timeslice_0 = described_class.find_by(course:, article:, start:)
      article_course_timeslice_1 = described_class.find_by(course:, article:, start: start + 1.day)
      article_course_timeslice_2 = described_class.find_by(course:, article:, start: start + 2.days)

      expect(article_course_timeslice_0).to be_nil
      expect(article_course_timeslice_1).to be_nil
      expect(article_course_timeslice_2).to be_nil

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')
      revision_data = { start: start_period, end: end_period, revisions: }
      described_class.update_article_course_timeslices(course, article.id, revision_data)

      article_course_timeslice_0 = described_class.find_by(course:, article:, start:)
      article_course_timeslice_1 = described_class.find_by(course:, article:, start: start + 1.day)
      article_course_timeslice_2 = described_class.find_by(course:, article:, start: start + 2.days)

      expect(article_course_timeslice_0.user_ids).to eq([25, 1])
      expect(article_course_timeslice_1.user_ids).to eq([1])
      expect(article_course_timeslice_2.user_ids).to eq([3, 7])
    end

    it 'updates the right article timeslices based on the revisions' do
      create(:article_course_timeslice, course:, article:, start:, end: start + 1.day)
      create(:article_course_timeslice, course:, article:, start: start + 1.day,
             end: start + 2.days)
      create(:article_course_timeslice, course:, article:, start: start + 2.days,
            end: start + 3.days)

      article_course_timeslice_0 = described_class.find_by(course:, article:, start:)
      article_course_timeslice_1 = described_class.find_by(course:, article:, start: start + 1.day)
      article_course_timeslice_2 = described_class.find_by(course:, article:, start: start + 2.days)

      expect(article_course_timeslice_0.user_ids).to eq([])
      expect(article_course_timeslice_1.user_ids).to eq([])
      expect(article_course_timeslice_2.user_ids).to eq([])

      start_period = start.strftime('%Y%m%d%H%M%S')
      end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')
      revision_data = { start: start_period, end: end_period, revisions: }
      described_class.update_article_course_timeslices(course, article.id, revision_data)

      # No new article course timeslices were created
      expect(described_class.where(course:, article:).count).to eq(3)
      article_course_timeslice_0 = described_class.find_by(course:, article:, start:)
      article_course_timeslice_1 = described_class.find_by(course:, article:, start: start + 1.day)
      article_course_timeslice_2 = described_class.find_by(course:, article:, start: start + 2.days)

      expect(article_course_timeslice_0.user_ids).to eq([25, 1])
      expect(article_course_timeslice_1.user_ids).to eq([1])
      expect(article_course_timeslice_2.user_ids).to eq([3, 7])
    end
  end

  describe '.search_by_course_and_user' do
    before do
      create(:article_course_timeslice, course:, article:, start:, end: start + 1.day,
             user_ids: [7])
      create(:article_course_timeslice, course:, article:, start: start + 1.day,
             end: start + 2.days, user_ids: [1, 2, 7])
      create(:article_course_timeslice, course:, article:, start: start + 2.days,
            end: start + 3.days, user_ids: [1, 2])
    end

    it 'fetches the records for the user' do
      timeslices_for_user = described_class.search_by_course_and_user(course, 7)
      expect(timeslices_for_user.count).to eq(2)
    end
  end

  describe '#update_cache_from_revisions' do
    it 'updates cache correctly' do
      expect(article_course_timeslice.revision_count).to eq(0)
      expect(article_course_timeslice.character_sum).to eq(100)
      expect(article_course_timeslice.references_count).to eq(3)
      expect(article_course_timeslice.user_ids).to eq([2, 4])
      expect(article_course_timeslice.new_article).to eq(false)
      subject
      expect(article_course_timeslice.revision_count).to eq(3)
      expect(article_course_timeslice.character_sum).to eq(348)
      expect(article_course_timeslice.references_count).to eq(3)
      expect(article_course_timeslice.user_ids).to eq([25, 1])
      expect(article_course_timeslice.new_article).to eq(true)
    end
  end
end
