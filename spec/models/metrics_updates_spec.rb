require 'rails_helper'

describe MetricsUpdates do
  describe '.last_update' do
    it 'adds the time of the metrics last update as a value to the settings table' do
      MetricsUpdates.last_update(Time.now)
      setting = Setting.find_by(key: 'metrics_update')
      expect(setting.value['last_update']).to be_within(2.seconds).of(Time.now)
    end
  end
end