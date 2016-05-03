require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/daily_update"

describe DailyUpdate do
  describe '#wait_until_constant_update_finishes' do
    it 'returns immediately if no constant update is running' do
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file)
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      expect_any_instance_of(DailyUpdate).not_to receive(:sleep)
      DailyUpdate.new
    end

    it 'creates a sleep file and waits for a constant update to finish' do
      expect(File).to receive(:delete).with('tmp/batch_sleep_10.pid').and_call_original
      allow_any_instance_of(DailyUpdate).to receive(:create_pid_file)
      allow_any_instance_of(DailyUpdate).to receive(:run_update)
      allow_any_instance_of(DailyUpdate).to receive(:daily_update_running?).and_return(false)

      expect_any_instance_of(DailyUpdate).to receive(:sleep)
      allow_any_instance_of(DailyUpdate).to receive(:constant_update_running?)
        .and_return(true, true, false)
      DailyUpdate.new
    end
  end
end
