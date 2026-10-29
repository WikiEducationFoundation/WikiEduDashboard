# frozen_string_literal: true

require 'rails_helper'

describe StoreTimesliceEditCounts do
  let(:course) { create(:course) }
  let(:stats_hash) { course.reload.course_stat.stats_hash }

  before do
    allow(TimesliceEditCounts).to receive(:by_namespace).with(course).and_return(0 => 7, 1 => 2)
    allow(TimesliceEditCounts).to receive(:by_wiki).with(course).and_return(1 => 9)
  end

  it 'stores the edits by namespace' do
    described_class.new(course)
    expect(stats_hash['edits_by_namespace']).to eq(0 => 7, 1 => 2)
  end

  it 'stores the edits by wiki' do
    described_class.new(course)
    expect(stats_hash['edits_by_wiki']).to eq(1 => 9)
  end

  describe '.clear' do
    it 'removes the stored edit counts, keeping the other stats' do
      create(:course_stats, course:,
                            stats_hash: { 'edits_by_namespace' => { 0 => 7 },
                                          'edits_by_wiki' => { 1 => 9 },
                                          'en.wikipedia.org-namespace-0' => { edited_count: 3 } })
      described_class.clear(course)
      expect(stats_hash.keys).to eq(['en.wikipedia.org-namespace-0'])
    end
  end

  it 'keeps the stats already stored for the course' do
    create(:course_stats, course:,
                          stats_hash: { 'en.wikipedia.org-namespace-0' => { edited_count: 3 } })
    described_class.new(course)
    expect(stats_hash['en.wikipedia.org-namespace-0']).to eq(edited_count: 3)
  end
end
