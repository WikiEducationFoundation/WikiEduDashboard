require 'rails_helper'

describe UpdateLog do
  describe '.log_update' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      UpdateLog.log_update(Time.now)
      setting = Setting.find_by(key: 'metrics_update')
      expect(setting.value['last_update']).to be_within(2.seconds).of(Time.now)
    end
  end

  describe '.last_update' do
    it 'returns the time of the last update' do
      UpdateLog.log_update(Time.at(1509710857))
      time = UpdateLog.last_update
      expect(time).to eq("12:07:37 - 03/11/2017")
    end

    it 'returns Not known as the last update is not defined' do
      time = UpdateLog.last_update
      expect(time).to eq(0)
    end
  end
end