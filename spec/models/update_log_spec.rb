require 'rails_helper'

describe UpdateLog do
  describe '.log_updates' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      UpdateLog.log_updates(Time.now, Time.now)
      setting = Setting.find_by(key: 'metrics_update')
      expect(setting.value['constant_update'].values.last['end_time']).to be_within(2.seconds).of(Time.now)
    end
  end

  describe '.last_update' do
    it 'returns the time of the last update' do
      UpdateLog.log_updates(Time.now, Time.now)
      time = UpdateLog.last_update
      expect(time).to be_within(2.seconds).of(Time.now)
    end

    it 'returns Not known as the last update is not defined' do
      time = UpdateLog.last_update
      expect(time).to eq(nil)
    end
  end

  describe '.log_delay' do
    it 'adds the average delay time to the settings table' do
      UpdateLog.log_updates(Time.parse("2017-12-06 11:11:33 +0100"), Time.parse("2017-12-06 13:11:33 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 13:13:33 +0100"), Time.parse("2017-12-06 15:13:33 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 15:30:00 +0100"), Time.parse("2017-12-06 21:30:00 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 21:45:00 +0100"), Time.parse("2017-12-06 22:45:00 +0100"))
      delay = Setting.find_by(key: 'metrics_update').value["average_delay"]
      expect(delay).to eq(11469)
    end
  end


  describe '.average_delay' do
    it 'returns the average delay time for updates' do
      UpdateLog.log_updates(Time.parse("2017-12-06 11:11:33 +0100"), Time.parse("2017-12-06 13:11:33 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 13:13:33 +0100"), Time.parse("2017-12-06 15:13:33 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 15:30:00 +0100"), Time.parse("2017-12-06 21:30:00 +0100"))
      UpdateLog.log_updates(Time.parse("2017-12-06 21:45:00 +0100"), Time.parse("2017-12-06 22:45:00 +0100"))
      delay = UpdateLog.average_delay
      expect(delay).to eq(11469)
    end

    it 'returns nil if the there was only one update' do
      UpdateLog.log_updates(Time.parse("2017-12-06 11:11:33 +0100"), Time.parse("2017-12-06 13:11:33 +0100"))
      delay = UpdateLog.average_delay
      expect(delay).to be(nil)
    end

    it 'returns nil if there were no updates' do
      delay = UpdateLog.average_delay
      expect(delay).to be(nil)
    end
  end

end