# frozen_string_literal: true

require 'rails_helper'

describe UpdateLog do
  describe '.log_updates' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      UpdateLog.new.log_updates({"start_time" => Time.now, "end_time" => Time.now})
      setting = UpdateLog.new.setting_record
      expect(setting.value['constant_update'].values.last['end_time'])
        .to be_within(2.seconds).of(Time.now)
    end

    it 'adds a maximum of 10 records' do
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      UpdateLog.new.log_updates({"start_time" => Time.now,
                                 "end_time" => Time.now})
      number_of_updates = UpdateLog.new.setting_record.value['constant_update'].keys.length
      expect(number_of_updates).to be(10)
    end

  end
  describe '.last_update' do
    it 'returns the time of the last update' do
      UpdateLog.new.log_updates({"start_time" => Time.now, "end_time" => Time.now})
      time = UpdateLog.new.last_update
      expect(time).to be_within(5.seconds).of(Time.now)
    end

    it 'returns nil as the last update is not defined' do
      time = UpdateLog.new.last_update
      expect(time).to eq(nil)
    end
  end

  describe '.log_delay' do
    it 'adds the average delay time to the settings table' do
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 11:11:33 +0100"),
                                "end_time" => Time.parse("2017-12-06 13:11:33 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 13:13:33 +0100"),
                                "end_time" => Time.parse("2017-12-06 15:13:33 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 15:30:00 +0100"),
                                "end_time" => Time.parse("2017-12-06 21:30:00 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 21:45:00 +0100"),
                                "end_time" => Time.parse("2017-12-06 22:45:00 +0100"))
      delay = UpdateLog.new.setting_record.value["average_delay"]
      expect(delay).to eq(11469)
    end
  end

  describe '.average_delay' do
    it 'returns the average delay time for updates' do
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 11:11:33 +0100"),
                                "end_time" => Time.parse("2017-12-06 13:11:33 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 13:13:33 +0100"),
                                "end_time" => Time.parse("2017-12-06 15:13:33 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 15:30:00 +0100"),
                                "end_time" => Time.parse("2017-12-06 21:30:00 +0100"))
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 21:45:00 +0100"),
                                "end_time" => Time.parse("2017-12-06 22:45:00 +0100"))
      delay = UpdateLog.new.average_delay
      expect(delay).to eq(11469)
    end

    it 'returns nil if there were no updates' do
      delay = UpdateLog.new.average_delay
      expect(delay).to be(nil)
    end

    it 'returns nil if the there was only one update' do
      UpdateLog.new.log_updates("start_time" => Time.parse("2017-12-06 11:11:33 +0100"),
                            "end_time" => Time.parse("2017-12-06 13:11:33 +0100"))
      delay = UpdateLog.new.average_delay
      expect(delay).to be(nil)
    end
  end
end
