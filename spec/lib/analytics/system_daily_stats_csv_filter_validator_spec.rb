# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/system_daily_stats_csv_filter_validator"

describe SystemDailyStatsCsvFilterValidator do
  describe '#errors' do
    it 'returns no errors for valid date filters' do
      filters = { start_date: 10.days.ago.to_date.to_s, end_date: Time.zone.today.to_s }
      expect(described_class.new(filters).errors).to be_empty
    end

    it 'returns no errors when no filters are provided' do
      expect(described_class.new({}).errors).to be_empty
    end

    it 'reports invalid start_date format' do
      filters = { start_date: 'not-a-date', end_date: Time.zone.today.to_s }
      errors = described_class.new(filters).errors
      expect(errors).to include('Invalid start_date: not-a-date')
    end

    it 'reports invalid end_date format' do
      filters = { start_date: Time.zone.today.to_s, end_date: 'garbage' }
      errors = described_class.new(filters).errors
      expect(errors).to include('Invalid end_date: garbage')
    end

    it 'reports both invalid dates' do
      filters = { start_date: 'bad', end_date: 'worse' }
      errors = described_class.new(filters).errors
      expect(errors.size).to eq(2)
    end

    it 'reports error when start_date is after end_date' do
      filters = { start_date: Time.zone.today.to_s, end_date: 10.days.ago.to_date.to_s }
      errors = described_class.new(filters).errors
      expect(errors).to include('start_date must be before end_date')
    end

    it 'skips range check when only start_date is provided' do
      filters = { start_date: Time.zone.today.to_s }
      expect(described_class.new(filters).errors).to be_empty
    end

    it 'skips range check when only end_date is provided' do
      filters = { end_date: Time.zone.today.to_s }
      expect(described_class.new(filters).errors).to be_empty
    end
  end
end
