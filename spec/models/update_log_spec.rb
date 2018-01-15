# frozen_string_literal: true

require 'rails_helper'

describe UpdateLog do
  describe '.log_updates' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      UpdateLog.new.log_updates('start_time' => Time.now, 'end_time' => Time.now)
      setting = UpdateLog.new.setting_record
      expect(setting.value['constant_update'].values.last['end_time'])
        .to be_within(2.seconds).of(Time.now)
    end

    it 'adds a maximum of 10 records' do
      15.times do
        UpdateLog.new.log_updates('start_time' => Time.now, 'end_time' => Time.now)
      end
      number_of_updates = UpdateLog.new.setting_record.value['constant_update'].size
      expect(number_of_updates).to be(10)
    end
  end

  describe '.last_update' do
    it 'returns the time of the last update' do
      UpdateLog.new.log_updates('start_time' => Time.now, 'end_time' => Time.now)
      time = UpdateLog.new.updates['last_update']
      expect(time).to be_within(5.seconds).of(Time.now)
    end
  end

  describe '.average_delay' do
    it 'adds the average delay time to the settings table' do
      UpdateLog.new.log_updates('start_time' => 14.hours.ago, 'end_time' => 12.hours.ago)
      UpdateLog.new.log_updates('start_time' => 12.hours.ago, 'end_time' => 9.hours.ago)
      UpdateLog.new.log_updates('start_time' => 9.hours.ago, 'end_time' => 8.hours.ago)
      UpdateLog.new.log_updates('start_time' => 8.hours.ago, 'end_time' => 6.hours.ago)
      delay = UpdateLog.new.setting_record.value['average_delay']
      expect(delay).to eq(7200)
    end
  end

  describe '.average_delay' do
    it 'returns the average delay time for updates' do
      UpdateLog.new.log_updates('start_time' => 14.hours.ago, 'end_time' => 12.hours.ago)
      UpdateLog.new.log_updates('start_time' => 12.hours.ago, 'end_time' => 9.hours.ago)
      UpdateLog.new.log_updates('start_time' => 9.hours.ago, 'end_time' => 8.hours.ago)
      UpdateLog.new.log_updates('start_time' => 8.hours.ago, 'end_time' => 6.hours.ago)
      delay = UpdateLog.new.updates['average_delay']
      expect(delay).to eq(7200)
    end

    it 'returns nil if the there was only one update' do
      UpdateLog.new.log_updates('start_time' => 10.hours.ago, 'end_time' => 8.hours.ago)
      delay = UpdateLog.new.updates['average_delay']
      expect(delay).to be(nil)
    end
  end
end
