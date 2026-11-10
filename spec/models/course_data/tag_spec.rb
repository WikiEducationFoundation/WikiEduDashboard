# frozen_string_literal: true

require 'rails_helper'

describe Tag do
  describe '.summaries' do
    let(:early) { create(:course, slug: 'a/early', start: '2024-01-01', end: '2024-06-01') }
    let(:late) { create(:course, slug: 'a/late', start: '2025-01-01', end: '2025-06-01') }

    before do
      create(:tag, course: early, tag: 'shared_tag', key: 'shared')
      create(:tag, course: late, tag: 'shared_tag', key: 'shared')
      create(:tag, course: early, tag: 'single_tag', key: 'single')
    end

    it 'counts courses per tag and reports the latest start, most-used first' do
      summaries = described_class.summaries
      expect(summaries.map(&:tag)).to eq(%w[shared_tag single_tag])
      expect(summaries.first.course_count).to eq(2)
      expect(summaries.first.latest_start.to_date).to eq(Date.new(2025, 1, 1))
    end

    it 'keeps only tags containing the query' do
      expect(described_class.summaries(query: 'single').map(&:tag)).to eq(['single_tag'])
    end

    it 'treats LIKE wildcards in the query literally' do
      expect(described_class.summaries(query: '%')).to be_empty
    end

    it 'leaves out tags whose course no longer exists' do
      create(:tag, course_id: 0, tag: 'orphan_tag', key: 'orphan')
      expect(described_class.summaries.map(&:tag)).not_to include('orphan_tag')
    end
  end
end
