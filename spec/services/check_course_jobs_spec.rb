# frozen_string_literal: true

require 'rails_helper'

require_dependency "#{Rails.root}/lib/data_cycle/schedule_course_updates"

describe CheckCourseJobs do
  let(:course) { create(:course) }

  let(:subject) do
    described_class.new(course)
  end

  describe '#health_report' do
    it 'runs without error' do
      subject.health_report
    end
  end

  describe '#expected_digest' do
    it 'produces a plausible string' do
      expect(subject.expected_digest).to match(/uniquejobs/)
    end
  end

  describe '#find_job' do
    context 'when no update is scheduled' do
      it 'returns nil' do
        expect(subject.find_job).to be_nil
      end
    end

    context 'when there is an update scheduled' do
      before do
        Sidekiq::Testing.disable!
        CourseDataUpdateWorker.set(queue: 'test').perform_async(course.id)
      end

      after { Sidekiq::Testing.inline! }

      it 'returns the update job' do
        expect(subject.find_job).to be_a(Sidekiq::Job)
      end
    end
  end

  describe '#delete_orphan_lock' do
    context 'when a digest is there' do
      before do
        Sidekiq::Testing.disable!
        SidekiqUniqueJobs::Locksmith.new({ 'jid' => 1234,
                                           'unique_digest' => subject.expected_digest }).lock
      end

      after { Sidekiq::Testing.inline! }

      it 'course worker does not exist, deletes orphan lock' do
        expect(subject.delete_orphan_lock).to eq true
      end

      it 'course worker is already exists, does not delete the orphan lock' do
        CourseDataUpdateWorker.set(queue: 'test').perform_async(course.id)
        expect(subject.delete_orphan_lock).to eq false
      end
    end
  end

  describe '#delete_unique_lock' do
    it 'runs without error' do
      subject.delete_unique_lock
    end
  end
end
