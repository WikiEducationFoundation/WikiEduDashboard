# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/system_stats_csv_builder"

describe SystemStatsCsvBuilder do
  let!(:stat_1) do
    create(:system_stat, snapshot_date: 10.days.ago.to_date,
                         total_edits: 500,
                         total_article_views: 10_000)
  end

  let!(:stat_2) do
    create(:system_stat, snapshot_date: 2.days.ago.to_date,
                         total_edits: 1200,
                         total_article_views: 25_000)
  end

  let!(:stat_old) do
    create(:system_stat, snapshot_date: 60.days.ago.to_date,
                         total_edits: 100,
                         total_article_views: 1000)
  end

  describe '#generate_csv' do
    it 'includes headers and snapshot values within the specified date range' do
      start_date = 15.days.ago.to_date.to_s
      builder = described_class.new(start_date:, end_date: Time.zone.today.to_s)
      csv = builder.generate_csv
      expect(csv).to include('snapshot_date')
      expect(csv).to include('new_editors_count_with_preregistration')
      expect(csv).to include(stat_1.snapshot_date.to_s)
      expect(csv).to include(stat_2.snapshot_date.to_s)
      expect(csv).not_to include(stat_old.snapshot_date.to_s)
    end

    it 'defaults to 30-day range when no dates provided' do
      builder = described_class.new
      csv = builder.generate_csv
      expect(csv).to include(stat_1.snapshot_date.to_s)
      expect(csv).to include(stat_2.snapshot_date.to_s)
      expect(csv).not_to include(stat_old.snapshot_date.to_s)
    end

    it 'produces headers-only CSV when no records exist in range' do
      builder = described_class.new(start_date: 90.days.ago.to_date.to_s,
                                    end_date: 80.days.ago.to_date.to_s)
      csv = builder.generate_csv
      lines = csv.strip.split("\n")
      expect(lines.size).to eq(1)
      expect(lines.first).to include('snapshot_date')
    end

    it 'returns empty result when start_date is after end_date' do
      builder = described_class.new(start_date: Time.zone.today.to_s,
                                    end_date: 30.days.ago.to_date.to_s)
      csv = builder.generate_csv
      lines = csv.strip.split("\n")
      expect(lines.size).to eq(1) # headers only
    end

    it 'gracefully handles invalid date strings by falling back to defaults' do
      builder = described_class.new(start_date: 'garbage', end_date: 'not-a-date')
      csv = builder.generate_csv
      expect(csv).to include('snapshot_date')
      # Should fall back to default 30-day range
      expect(csv).to include(stat_1.snapshot_date.to_s)
    end

    it 'emits rows in snapshot_date order, not id order' do
      # Create a row with a newer id but an older date to confirm ordering
      # is by snapshot_date, not by primary key.
      backfilled = create(:system_stat, snapshot_date: 5.days.ago.to_date, total_edits: 999)
      builder = described_class.new(start_date: 15.days.ago.to_date.to_s,
                                    end_date: Time.zone.today.to_s)
      csv = builder.generate_csv
      dates = CSV.parse(csv, headers: true).map { |row| row['snapshot_date'] }
      expect(dates).to eq(dates.sort)
      expect(dates).to include(backfilled.snapshot_date.to_s)
    end
  end
end
