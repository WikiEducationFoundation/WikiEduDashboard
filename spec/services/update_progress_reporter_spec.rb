# frozen_string_literal: true

require 'rails_helper'

describe UpdateProgressReporter do
  describe 'with no worker (no-op mode)' do
    subject(:reporter) { described_class.new }

    it 'silently ignores phase' do
      expect { reporter.phase('uploads', total: 50) }.not_to raise_error
    end

    it 'silently ignores progress' do
      expect { reporter.progress(at: 1, total: 10, message: 'x') }.not_to raise_error
    end
  end

  describe 'with a worker' do
    let(:worker) do
      instance_double('CourseDataUpdateWorker',
                      store: nil, at: nil, total: nil)
    end

    subject(:reporter) { described_class.new(worker) }

    it 'writes initialization state on construction' do
      expect(worker).to receive(:store).with(hash_including(:started_at, :phase_started_at,
                                                            phase: 'initialization'))
      described_class.new(worker)
    end

    it 'records a new phase with reset progress fields' do
      reporter
      expect(worker).to receive(:store).with(hash_including(phase: 'uploads', at: 0, total: 0,
                                                            pct_complete: 0, message: ''))
      expect(worker).to receive(:total).with(50)
      reporter.phase('uploads', total: 50)
    end

    it 'reports progress through worker.at/total' do
      reporter
      expect(worker).to receive(:total).with(100)
      expect(worker).to receive(:at).with(42, 'enwiki: 2024-09-15')
      reporter.progress(at: 42, total: 100, message: 'enwiki: 2024-09-15')
    end

    it 'skips total when not provided to progress' do
      reporter
      expect(worker).not_to receive(:total)
      expect(worker).to receive(:at).with(7, nil)
      reporter.progress(at: 7)
    end
  end

  describe '#pause_until_no_backup' do
    let(:worker) { instance_double('CourseDataUpdateWorker', store: nil, at: nil, total: nil) }
    let(:backup) { create(:backup, status: 'running') }

    subject(:reporter) { described_class.new(worker) }

    before do
      stub_const('UpdateProgressReporter::SLEEP_TIME_IN_SECONDS', 0)
      reporter # construct so the initialization store call is consumed
    end

    it 'sleeps once and then wakes up when backup finishes' do
      allow(Backup).to receive(:current_backup).and_return(backup, nil)
      expect(worker).to receive(:store).with(phase: 'sleeping_1').ordered
      expect(worker).to receive(:store).with(phase: 'woke_up').ordered
      reporter.pause_until_no_backup
    end

    it 'sleeps repeatedly while backups continue' do
      allow(Backup).to receive(:current_backup).and_return(backup, backup, nil)
      expect(worker).to receive(:store).with(phase: 'sleeping_1').ordered
      expect(worker).to receive(:store).with(phase: 'sleeping_2').ordered
      expect(worker).to receive(:store).with(phase: 'woke_up').ordered
      reporter.pause_until_no_backup
    end

    it 'does not sleep when no backup is running' do
      allow(Backup).to receive(:current_backup).and_return(nil)
      expect(worker).not_to receive(:store)
        .with(hash_including(phase: a_string_matching(/sleeping/)))
      expect(worker).to receive(:store).with(phase: 'woke_up')
      reporter.pause_until_no_backup
    end
  end
end
