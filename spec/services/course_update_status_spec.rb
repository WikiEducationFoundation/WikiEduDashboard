# frozen_string_literal: true

require 'rails_helper'

describe CourseUpdateStatus do
  let(:course) { create(:course) }

  def stub_work_set(work_payloads)
    work_doubles = work_payloads.map do |payload, run_at|
      instance_double(Sidekiq::Work, payload: payload.to_json, run_at: run_at)
    end
    workset = double('WorkSet')
    allow(workset).to receive(:each) do |&block|
      work_doubles.each_with_index { |w, i| block.call("pid#{i}", "tid#{i}", w) }
    end
    allow(Sidekiq::WorkSet).to receive(:new).and_return(workset)
  end

  context 'when no CourseDataUpdateWorker is running for the course' do
    before do
      stub_work_set([
                      [{ 'class' => 'CourseDataUpdateWorker', 'args' => [course.id + 999],
                         'jid' => 'other', 'queue' => 'long_update' }, Time.at(1_700_000_000)],
                      [{ 'class' => 'OtherWorker', 'args' => [course.id],
                         'jid' => 'noise', 'queue' => 'default' }, Time.at(1_700_000_000)]
                    ])
    end

    it 'returns running: false' do
      expect(described_class.new(course).result).to eq(running: false)
    end
  end

  context 'when the course has a running update worker' do
    let(:jid) { 'abc123' }
    let(:run_at) { Time.at(1_700_000_000) }

    before do
      stub_work_set([
                      [{ 'class' => 'CourseDataUpdateWorker', 'args' => [course.id],
                         'jid' => jid, 'queue' => 'long_update' }, run_at]
                    ])
      allow(Sidekiq::Status).to receive(:get_all).with(jid).and_return(
        'started_at' => '1700000001', 'phase' => 'timeslices',
        'phase_started_at' => '1700000500', 'at' => '42',
        'total' => '884', 'pct_complete' => '4',
        'message' => 'enwiki: 2024-09-15', 'updated_at' => '1700000700'
      )
    end

    it 'returns the running job progress' do
      result = described_class.new(course).result
      expect(result).to include(running: true, jid: jid, queue: 'long_update',
                                run_at: run_at.to_i, phase: 'timeslices',
                                at: 42, total: 884, pct_complete: 4,
                                message: 'enwiki: 2024-09-15')
    end
  end

  context 'when sidekiq-status data has expired but the job is still in flight' do
    let(:jid) { 'abc123' }

    before do
      stub_work_set([
                      [{ 'class' => 'CourseDataUpdateWorker', 'args' => [course.id],
                         'jid' => jid, 'queue' => 'long_update' }, Time.at(1_700_000_000)]
                    ])
      allow(Sidekiq::Status).to receive(:get_all).with(jid).and_return({})
    end

    it 'still reports the job as running with nil fields' do
      result = described_class.new(course).result
      expect(result[:running]).to eq(true)
      expect(result[:jid]).to eq(jid)
      expect(result[:phase]).to be_nil
      expect(result[:at]).to be_nil
    end
  end
end
