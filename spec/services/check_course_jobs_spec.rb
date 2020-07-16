# frozen_string_literal: true

require 'rails_helper'

describe CheckCourseJobs do
  let(:course) { create(:course, needs_update: true) }

  let(:subject) do
    described_class.new(course)
  end

  describe '#job_exists? and #find_job' do
    context 'when no update is scheduled' do
      it 'returns false' do
        expect(subject.find_job).to be nil
        expect(subject.job_exists?).to eq false
      end
    end

    context 'when there is an update queued' do
      before do
        Sidekiq::Testing.disable!
        CourseDataUpdateWorker.set(queue: 'test').perform_async(course.id)
      end

      after do
        # Clearing the queue, to delete the job after the test
        Sidekiq::Queue.new('test').clear
        Sidekiq::Testing.inline!
      end

      it 'returns true' do
        expect(subject.find_job).to be_a Sidekiq::Job
        expect(subject.job_exists?).to eq true
      end
    end

    context 'when there is an update job running' do
      # Value returned by Sidekiq::Worker.new for currently running jobs
      # Refer to Sidekiq API Workers Wiki
      let(:currently_running_jobs) do
        [
          [
            'process_id_1',
            'thread_id_1',
            { 'queue' => 'test',
              'run_at' => Time.zone.now,
              'payload' => {
                'retry' => false,
                'queue' => 'test',
                'class' => 'SomeOtherWorker',
                'args' => [567],
                'jid' => '5678',
                'enqueued_at' => 3456.7890
              } }
          ], [
            'process_id_2',
            'thread_id_2',
            { 'queue' => 'test',
              'run_at' => Time.zone.now,
              'payload' => {
                'retry' => false,
                'queue' => 'test',
                'class' => 'CourseDataUpdateWorker',
                'args' => [course.id],
                'jid' => '1234',
                'enqueued_at' => 1234.5678
              } }
          ]
        ]
      end

      it 'returns true' do
        allow(Sidekiq::Workers).to receive(:new).and_return(currently_running_jobs)
        worker_hash = subject.find_job
        expect(worker_hash).to be_a Hash
        expect(worker_hash['payload']['class']).to eq 'CourseDataUpdateWorker'
        expect(worker_hash['payload']['args']).to eq [course.id]
        expect(subject.job_exists?).to eq true
      end
    end
  end

  describe '#lock_exists?' do
    it 'detects lock when it exists' do
      SidekiqUniqueJobs::Locksmith.new({ 'jid' => 1234,
                                         'unique_digest' => subject.expected_digest }).lock
      expect(subject.lock_exists?).to eq true

      # Deleting the digest after the test
      SidekiqUniqueJobs::Digests.delete_by_digest subject.expected_digest
    end

    it 'detects no lock when it does not exist' do
      expect(subject.lock_exists?).to eq false
    end
  end

  describe '#expected_digest' do
    it 'produces a plausible string' do
      expect(subject.expected_digest).to match(/uniquejobs/)
    end
  end

  describe '#delete_orphan_lock' do
    before do
      Sidekiq::Testing.disable!
      SidekiqUniqueJobs::Locksmith.new({ 'jid' => 1234,
                                         'unique_digest' => subject.expected_digest }).lock
    end

    after do
      # Deleting the digest after the test
      SidekiqUniqueJobs::Digests.delete_by_digest subject.expected_digest
      Sidekiq::Testing.inline!
    end

    context 'when a lock is there and no job exists' do
      let(:days_ago_update_log) do
        { 'start_time' => 4.days.ago,
          'end_time' => 3.days.ago,
          'error_count' => 0,
          'sentry_tag_uuid' => 'abcd-12ef' }
      end
      let(:hours_ago_update_log) do
        { 'start_time' => 2.hours.ago,
          'end_time' => 1.hour.ago,
          'error_count' => 0,
          'sentry_tag_uuid' => 'wxyz-34jk' }
      end
      let(:orphan_lock_update_log) do
        { 'orphan_lock_failure' => 30.minutes.ago }
      end
      let(:orphan_not_expected) do
        { 'update_logs' => {  1 => days_ago_update_log,
                              2 => hours_ago_update_log,
                              3 => orphan_lock_update_log } }
      end
      let(:orphan_expected_1) do
        { 'update_logs' => { 1 => days_ago_update_log,
                             2 => orphan_lock_update_log } }
      end

      let(:orphan_expected_2) do
        { 'update_logs' => { 1 => orphan_lock_update_log } }
      end

      it 'last update hours ago, does not delete orphan lock' do
        course.flags = orphan_not_expected
        expect(subject.delete_orphan_lock).to eq false
      end

      it 'last update some days ago, deletes orphan lock' do
        course.flags = orphan_expected_1
        expect(subject.delete_orphan_lock).to eq true
      end

      it 'no successful update yet, deletes orphan lock' do
        course.flags = orphan_expected_2
        expect(subject.delete_orphan_lock).to eq true
      end
    end

    context 'when a lock is there and a job exists' do
      it 'no update logs, orphan expected, does not delete the orphan lock' do
        CourseDataUpdateWorker.set(queue: 'test').perform_async(course.id)
        expect(subject.delete_orphan_lock).to eq false

        # Clearing the queue, to delete the job after the test
        Sidekiq::Queue.new('test').clear
      end
    end
  end
end
