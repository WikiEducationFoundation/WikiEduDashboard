# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/views_update"

describe ViewsUpdate do
  before do
    create(:course, start: '2015-03-20', end: 1.month.from_now,
                    flags: { salesforce_id: 'a0f1a9063a1Wyad' })
  end

  describe 'on initialization' do
    it 'calls lots of update routines' do
      expect(ViewImporter).to receive(:update_all_views)
      update = ViewsUpdate.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Updating article views/).any?).to eq(true)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Raven).to receive(:capture_message)
      allow(ViewImporter).to receive(:update_all_views).and_raise(StandardError)
      expect { ViewsUpdate.new }.to raise_error(StandardError)
      expect(Raven).to have_received(:capture_message)
    end
  end

  context 'when a pid file is present' do
    it 'deletes the pid file for a non-running process' do
      allow_any_instance_of(ViewsUpdate).to receive(:create_pid_file)
      allow_any_instance_of(ViewsUpdate).to receive(:run_update)
      File.open('tmp/batch_update_constantly.pid', 'w') { |f| f.puts '123456789' }
      ViewsUpdate.new
      expect(File.exist?('tmp/batch_update_views.pid')).to eq(false)
    end
  end
end
