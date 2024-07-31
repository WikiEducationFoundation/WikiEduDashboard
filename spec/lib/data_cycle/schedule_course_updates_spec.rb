# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/schedule_course_updates"

describe ScheduleCourseUpdates do
  let(:fast_update_logs) do
    {
      'update_logs' => { 1 => { 'start_time' => 2.seconds.ago, 'end_time' => 1.second.ago } }
    }
  end

  let(:medium_update_logs) do
    {
      'update_logs' => { 1 => { 'start_time' => 2.minutes.ago, 'end_time' => 1.second.ago } }
    }
  end

  let(:slow_update_logs) do
    {
      'update_logs' => { 1 => { 'start_time' => 2.hours.ago, 'end_time' => 1.second.ago } }
    }
  end

  describe 'on initialization' do
    before do
      create(:editathon, start: 1.day.ago, end: 2.hours.from_now,
                         slug: 'ArtFeminism/Test_Editathon')
      create(:course, start: 1.day.ago, end: 2.months.from_now,
                      slug: 'Medium/Course', needs_update: true)
      create(:course, start: 1.day.ago, end: 1.year.from_now,
                      slug: 'Long/Program')
      create(:course, slug: 'Fast/Updates', flags: fast_update_logs)
      create(:course, slug: 'Medium/Updates', flags: medium_update_logs)
      create(:course, slug: 'Slow/Updates', flags: slow_update_logs)
      create(:course, slug: 'VeryLong/Updates', flags: { very_long_updates: true })
    end

    it 'calls the revisions and articles updates on courses currently taking place' do
      expect(UpdateCourseStatsTimeslice).to receive(:new).exactly(7).times
      update = described_class.new
      sentry_logs = update.instance_variable_get(:@sentry_logs)
      expect(sentry_logs.grep(/Short update latency/).any?).to eq(true)
    end

    it 'clears the needs_update flag from courses' do
      expect(Course.where(needs_update: true).any?).to be(true)
      described_class.new
      expect(Course.where(needs_update: true).any?).to be(false)
    end

    it 'reports logs to sentry even when it errors out' do
      allow(Sentry).to receive(:capture_message)
      expect(CourseDataUpdateWorker).to receive(:update_course)
        .and_raise(StandardError)
      expect { described_class.new }.to raise_error(StandardError)
      expect(Sentry).to have_received(:capture_message)
    end
  end

  describe 'on calling update workers' do
    let(:queue) { 'medium_update' }
    let(:short_queue) { 'short_update' }
    let(:very_long_queue) { 'very_long_update' }
    let(:flags) { nil }

    context 'a course has no job enqueued' do
      before do
        Sidekiq::Testing.disable!
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        slug: 'Medium/Course', needs_update: true, flags:)
        create(:course, slug: 'VeryLong/Updates', needs_update: true,
                        flags: { very_long_update: true })
      end

      after do
        # Clearing the queue after the test
        Sidekiq::Queue.new(queue).clear
        Sidekiq::Queue.new(short_queue).clear
        Sidekiq::Queue.new(very_long_queue).clear
        Sidekiq::Testing.inline!
      end

      it 'adds the right kind of job to the right queue, when no orphan lock' do
        # No job before
        expect(Sidekiq::Queue.new(queue).size).to eq 0
        described_class.new

        # 2 jobs enqueued by ScheduleCourseUpdates: one medium, one very long
        expect(Sidekiq::Queue.new(queue).size).to eq 1
        job = Sidekiq::Queue.new(queue).first
        expect(job.klass).to eq 'CourseDataUpdateWorker'
        expect(job.args).to eq [Course.first.id]
        expect(Sidekiq::Queue.new(very_long_queue).size).to eq(1)
      end
    end
  end
end
