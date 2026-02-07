# frozen_string_literal: true

require 'rails_helper'

describe System::BackupsController, type: :request do
  let(:work) do
    ['server-15ALC6:390735:407ff4a2b287',
     '81ib',
     { 'queue'=>'medium_update',
     'payload'=>
       { 'class'=>'CourseDataUpdateWorker',
       'jid'=>'e118d576de83c8e44526bba7' },
     'run_at'=>1769012340 }]
  end

  describe '#can_start_backup' do
    context 'when no current backup' do
      it 'returns 503 service unavailable' do
        get '/system/can_start_backup.json'
        expect(response.status).to eq(503)
      end
    end

    context 'when backup is waiting' do
      before { create(:backup, status: 'waiting') }

      context 'when no jobs are running' do
        it 'returns 200 OK' do
          get '/system/can_start_backup.json'
          expect(response.status).to eq(200)
        end
      end

      context 'when all jobs are sleeping' do
        before do
          workset = instance_double(Sidekiq::WorkSet)
          allow(Sidekiq::WorkSet).to receive(:new).and_return(workset)
          allow(workset).to receive(:all?).and_return(true)
        end

        it 'returns 200 OK' do
          get '/system/can_start_backup.json'
          expect(response.status).to eq(200)
        end
      end

      context 'when any job woke up' do
        before do
          workset = instance_double(Sidekiq::WorkSet)
          allow(Sidekiq::WorkSet).to receive(:new).and_return(workset)
          allow(workset).to receive(:all?).and_return(false)
        end

        it 'returns 503 service unavailable' do
          get '/system/can_start_backup.json'
          expect(response.status).to eq(503)
        end
      end
    end
  end
end
