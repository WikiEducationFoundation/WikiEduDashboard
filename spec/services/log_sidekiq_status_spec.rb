# frozen_string_literal: true

require 'rails_helper'

describe LogSidekiqStatus do
  describe '#pause_until_no_backup' do
    subject(:logger) { described_class.new(store) }

    let(:store) { instance_double(Proc) }
    let(:backup) { create(:backup, status: 'running') }

    before do
      stub_const('LogSidekiqStatus::SLEEP_TIME_IN_SECONDS', 0)
      allow(store).to receive(:call)
    end

    describe '#pause_until_no_backup' do
      context 'when a backup is running and then finishes' do
        before do
          allow(Backup).to receive(:current_backup)
            .and_return(backup, nil)
        end

        it 'sleeps once and then wakes up' do
          logger.pause_until_no_backup

          expect(store).to have_received(:call).with(phase: 'sleeping_1')
          expect(store).to have_received(:call).with(phase: 'woke_up')
        end
      end

      context 'when a backup is running and multiple sleeps are required' do
        before do
          allow(Backup).to receive(:current_backup)
            .and_return(backup, backup, nil)
        end

        it 'sleeps twice and then wakes up' do
          logger.pause_until_no_backup

          expect(store).to have_received(:call).with(phase: 'sleeping_1')
          expect(store).to have_received(:call).with(phase: 'sleeping_2')
          expect(store).to have_received(:call).with(phase: 'woke_up')
        end
      end

      context 'when no backup is running/waiting' do
        before do
          allow(Backup).to receive(:current_backup).and_return(nil)
        end

        it 'does not sleep and immediately wakes up' do
          logger.pause_until_no_backup

          expect(store).not_to have_received(:call).with(hash_including(:sleeping))
          expect(store).to have_received(:call).with(phase: 'woke_up')
        end
      end
    end
  end
end
