# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_user_wiki_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  wiki_id          :integer          not null
#  article_id       :integer          not null
#  user_id          :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  first_revision   :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe ArticleCourseUserWikiTimeslice, type: :model do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:user) { create(:user) }
  let(:start) { 1.month.ago.beginning_of_day }
  let(:course) { create(:course, start:, end: 1.month.from_now.beginning_of_day) }
  let(:article) { create(:article) }
  let(:article_id) { article.id }

  let(:revision1) do
    build(:revision_on_memory, article_id:,
           characters: 123,
           features: { 'num_ref' => 4 },
           features_previous: { 'num_ref' => 0 },
           user_id: user.id,
           date: start + 1.hour,
           new_article: true)
  end
  let(:revision2) do
    build(:revision_on_memory, article_id:,
           characters: -65,
           features: { 'num_ref' => 1 },
           features_previous: { 'num_ref' => 2 },
           user_id: user.id,
           date: start + 10.hours)
  end
  let(:revision3) do
    build(:revision_on_memory, article_id:,
           characters: 225,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: user.id,
           date: start + 12.hours)
  end
  let(:revision4) do
    build(:revision_on_memory, article_id:,
           characters: 34,
           deleted: true,
           features: { 'num_ref' => 2 },
           features_previous: { 'num_ref' => 0 },
           user_id: user.id,
           date: start + 16.hours)
  end
  let(:revision5) do
    build(:revision_on_memory, article_id:,
           characters: 120,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: user.id,
           date: start + 12.hours,
           system: true)
  end
  let(:revisions) { [revision1, revision2, revision3, revision4, revision5] }

  describe '.update_article_course_user_wiki_timeslices' do
    before do
      create(:course_wiki_timeslice, course:, wiki:, start:, end: start + 1.day)
    end

    let(:start_period) { start.strftime('%Y%m%d%H%M%S') }
    let(:end_period) { (start + 1.day - 1.second).strftime('%Y%m%d%H%M%S') }
    let(:revision_data) { { start: start_period, end: end_period, revisions: } }

    it 'creates the right timeslice based on the revisions' do
      expect(described_class.find_by(course:, article:, user:, wiki:, start:)).to be_nil

      described_class.update_article_course_user_wiki_timeslices(
        course, article_id, user.id, wiki, revision_data
      )

      timeslice = described_class.find_by(course:, article:, user:, wiki:, start:)
      expect(timeslice.revision_count).to eq(3)
      expect(timeslice.character_sum).to eq(348)
      expect(timeslice.references_count).to eq(3)
      expect(timeslice.new_article).to eq(true)
      expect(timeslice.first_revision).to eq(start + 1.hour)
    end

    it 'updates an existing timeslice based on the revisions' do
      create(:article_course_user_wiki_timeslice, course:, article:, user:, wiki:,
             start:, end: start + 1.day, revision_count: 0, character_sum: 0)

      described_class.update_article_course_user_wiki_timeslices(
        course, article_id, user.id, wiki, revision_data
      )

      timeslice = described_class.find_by(course:, article:, user:, wiki:, start:)
      expect(timeslice.revision_count).to eq(3)
      expect(timeslice.character_sum).to eq(348)
    end

    it 'sends a Sentry error when multiple timeslices are matched' do
      create(:course_wiki_timeslice, course:, wiki:, start: start + 1.day, end: start + 2.days)
      multi_end_period = (start + 55.hours).strftime('%Y%m%d%H%M%S')

      expect(Sentry).to receive(:capture_message)
        .with("Multiple article course user wiki timeslices matched for course #{course.slug}",
              level: 'error',
              extra: hash_including(course_id: course.id, wiki_id: wiki.id,
                                    article_id:, user_id: user.id,
                                    start: start_period, end: multi_end_period))

      described_class.update_article_course_user_wiki_timeslices(
        course, article_id, user.id, wiki,
        { start: start_period, end: multi_end_period, revisions: }
      )
    end
  end

  describe '#update_cache_from_revisions' do
    let(:timeslice) do
      create(:article_course_user_wiki_timeslice, course:, article:, user:, wiki:,
             character_sum: 100, references_count: 3, revision_count: 5)
    end

    it 'updates cache correctly' do
      timeslice.update_cache_from_revisions(revisions)
      expect(timeslice.revision_count).to eq(3)
      expect(timeslice.character_sum).to eq(348)
      expect(timeslice.references_count).to eq(3)
      expect(timeslice.new_article).to eq(true)
      expect(timeslice.first_revision).to eq(start + 1.hour)
    end

    it 'updates cache correctly if no live revisions' do
      timeslice.update_cache_from_revisions([revision4, revision5])
      expect(timeslice.revision_count).to eq(0)
      expect(timeslice.character_sum).to eq(0)
      expect(timeslice.references_count).to eq(0)
      expect(timeslice.new_article).to eq(false)
      expect(timeslice.first_revision).to be_nil
    end
  end
end
