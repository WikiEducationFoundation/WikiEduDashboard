# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/data_cycle/update_logger')

describe UpdateLogger do
  describe '.update_settings_record' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      described_class.update_settings_record('start_time' => Time.zone.now,
                                             'end_time' => Time.zone.now)
      record = Setting.find_or_create_by(key: 'metrics_update')
      expect(record.value['constant_update'].values.last['end_time'])
        .to be_within(2.seconds).of(Time.zone.now)
    end

    it 'adds a maximum of 10 records' do
      15.times do
        described_class.update_settings_record('start_time' => Time.zone.now,
                                               'end_time' => Time.zone.now)
      end
      record = Setting.find_or_create_by(key: 'metrics_update')
      number_of_updates = record.value['constant_update'].size
      expect(number_of_updates).to be(10)
    end

    it 'adds the average delay time to the settings table' do
      described_class.update_settings_record('start_time' => 14.hours.ago,
                                             'end_time' => 12.hours.ago)
      described_class.update_settings_record('start_time' => 12.hours.ago,
                                             'end_time' => 9.hours.ago)
      described_class.update_settings_record('start_time' => 9.hours.ago, 'end_time' => 8.hours.ago)
      described_class.update_settings_record('start_time' => 8.hours.ago, 'end_time' => 6.hours.ago)
      record = Setting.find_or_create_by(key: 'metrics_update')
      delay = record.value['average_delay']
      expect(delay).to eq(7200)
    end

    it 'does not set average delay if there was only one update' do
      described_class.update_settings_record('start_time' => 10.hours.ago,
                                             'end_time' => 8.hours.ago)
      record = Setting.find_or_create_by(key: 'metrics_update')
      delay = record.value['average_delay']
      expect(delay).to be(nil)
    end
  end
end
