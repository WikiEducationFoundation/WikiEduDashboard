# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/csv_edit_counts"

describe CsvEditCounts do
  let(:course) { create(:course) }
  let(:other_course) { create(:course, slug: 'Other/Course_(term)') }

  def store_edit_counts(course, by_namespace:, by_wiki: {})
    create(:course_stats, course:, stats_hash: { 'edits_by_namespace' => by_namespace,
                                                 'edits_by_wiki' => by_wiki })
  end

  describe '.by_namespace' do
    before { allow(TimesliceEditCounts).to receive(:by_namespace).and_return(0 => 4) }

    it 'returns the stored edits when the course has them' do
      store_edit_counts(course, by_namespace: { 0 => 7 })
      expect(described_class.by_namespace(course)).to eq(0 => 7)
    end

    it 'counts the edits from timeslices otherwise' do
      expect(described_class.by_namespace(course)).to eq(0 => 4)
    end
  end

  describe '.by_wiki' do
    before { allow(TimesliceEditCounts).to receive(:by_wiki).and_return(1 => 4) }

    it 'returns the stored edits when the course has them' do
      store_edit_counts(course, by_namespace: {}, by_wiki: { 1 => 9 })
      expect(described_class.by_wiki(course)).to eq(1 => 9)
    end

    it 'counts the edits from timeslices otherwise' do
      expect(described_class.by_wiki(course)).to eq(1 => 4)
    end
  end

  describe '.by_course_and_namespace' do
    before do
      allow(TimesliceEditCounts).to receive(:by_course_and_namespace)
        .and_return([other_course.id, 0] => 4)
    end

    it 'uses the stored edits for courses that have them and timeslices for the rest' do
      store_edit_counts(course, by_namespace: { 0 => 7, 1 => 2 })
      expect(described_class.by_course_and_namespace([course.id, other_course.id]))
        .to eq([course.id, 0] => 7, [course.id, 1] => 2, [other_course.id, 0] => 4)
    end

    it 'ignores course stats without stored edits' do
      create(:course_stats, course:, stats_hash: { 'en.wikipedia.org-namespace-0' => {} })
      expect(described_class.by_course_and_namespace([course.id, other_course.id]))
        .to eq([other_course.id, 0] => 4)
    end
  end
end
