# frozen_string_literal: true

require 'rails_helper'

describe CheckCourseJobs do
  let(:course) { create(:course) }

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

    context 'when there is an update scheduled' do
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
    context 'when a lock is there' do
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

      it 'course worker does not exist, deletes orphan lock' do
        expect(subject.delete_orphan_lock).to eq true
      end

      it 'course worker is already exists, does not delete the orphan lock' do
        CourseDataUpdateWorker.set(queue: 'test').perform_async(course.id)
        expect(subject.delete_orphan_lock).to eq false

        # Clearing the queue, to delete the job after the test
        Sidekiq::Queue.new('test').clear
      end
    end
  end
end
