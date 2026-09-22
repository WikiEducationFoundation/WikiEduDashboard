# frozen_string_literal: true

require 'rails_helper'

describe SystemStat do
  let!(:stat_today) do
    create(:system_stat, snapshot_date: Time.zone.today,
                         total_edits: 100_000,
                         wiki_stats: {
                           'en.wikipedia.org' => {
                             'edits' => 80_000,
                             'programs' => 200,
                             'articles_created' => 800,
                             'new_editors_with_preregistration' => 2_500
                           }
                         })
  end

  let!(:stat_yesterday) do
    create(:system_stat, snapshot_date: 1.day.ago.to_date,
                         total_edits: 99_000)
  end

  let!(:stat_old) do
    create(:system_stat, snapshot_date: 14.months.ago.to_date,
                         total_edits: 50_000)
  end

  describe 'validations' do
    it 'requires snapshot_date' do
      stat = build(:system_stat, snapshot_date: nil)
      expect(stat).not_to be_valid
      expect(stat.errors[:snapshot_date]).to be_present
    end

    it 'enforces uniqueness of snapshot_date' do
      duplicate = build(:system_stat,
                        snapshot_date: Time.zone.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:snapshot_date]).to be_present
    end
  end

  describe '.latest' do
    it 'returns only the most recent snapshot' do
      results = described_class.latest
      expect(results.length).to eq(1)
      expect(results.first).to eq(stat_today)
    end
  end

  describe '.current' do
    it 'returns the most recent snapshot record' do
      expect(described_class.current).to eq(stat_today)
    end

    it 'returns nil when no snapshots exist' do
      SystemStat.delete_all
      expect(described_class.current).to be_nil
    end
  end

  describe '.for_date_range' do
    it 'returns records within the specified date range ordered by date' do
      start_date = 2.days.ago.to_date
      end_date = Time.zone.today
      results = described_class.for_date_range(start_date, end_date)
      expect(results).to include(stat_yesterday, stat_today)
      expect(results).not_to include(stat_old)
      expect(results).to eq(results.sort_by(&:snapshot_date))
    end
  end

  describe '.recent_months' do
    it 'returns snapshots from the last 12 months by default' do
      results = described_class.recent_months
      expect(results).to include(stat_today, stat_yesterday)
      expect(results).not_to include(stat_old)
    end

    it 'accepts a custom month count' do
      results = described_class.recent_months(15)
      expect(results).to include(stat_today, stat_yesterday, stat_old)
    end
  end

  describe 'wiki_stats serialization' do
    it 'round-trips wiki_stats as a Hash with string keys' do
      reloaded = described_class.find(stat_today.id)
      expect(reloaded.wiki_stats).to be_a(Hash)
      expect(reloaded.wiki_stats.keys).to include('en.wikipedia.org')

      wiki_entry = reloaded.wiki_stats['en.wikipedia.org']
      expect(wiki_entry['edits']).to eq(80_000)
      expect(wiki_entry['programs']).to eq(200)
      expect(wiki_entry['articles_created']).to eq(800)
      expect(wiki_entry['new_editors_with_preregistration']).to eq(2_500)
    end

    it 'handles empty wiki_stats gracefully' do
      stat = create(:system_stat,
                    snapshot_date: 2.days.ago.to_date,
                    wiki_stats: {})
      reloaded = described_class.find(stat.id)
      expect(reloaded.wiki_stats).to eq({})
    end
  end
end
