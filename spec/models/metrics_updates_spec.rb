require 'rails_helper'

describe MetricsUpdates do
  describe '.last_update' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      MetricsUpdates.last_update(Time.now)
      setting = Setting.find_by(key: 'metrics_update')
      expect(setting.value['last_update']).to be_within(2.seconds).of(Time.now)
    end
  end

  describe '.time_update' do
    it 'returns the time of the last update' do
      MetricsUpdates.last_update(Time.now)
      time = MetricsUpdates.time_update
      expect(time).to be_within(2.seconds).of(Time.now)
    end

    it 'returns Not known as the last update is not defined' do
      time = MetricsUpdates.time_update
      expect(time).to eq("Not known")
    end
  end
end