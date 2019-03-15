# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/schedule_course_updates"

describe ScheduleCourseUpdates do
  describe 'on initialization' do
    before do
      create(:editathon, start: 1.day.ago, end: 2.hours.from_now,
                         slug: 'ArtFeminism/Test_Editathon')
      create(:course, start: 1.day.ago, end: 2.months.from_now,
                      slug: 'Medium/Course', needs_update: true)
      create(:course, start: 1.day.ago, end: 1.year.from_now,
                      slug: 'Long/Program')
    end

    it 'calls the revisions and articles updates on courses currently taking place' do
      expect(UpdateCourseStats).to receive(:new).thrice
      expect(Raven).to receive(:capture_message).and_call_original
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
      allow(Raven).to receive(:capture_message)
      expect(UpdateCourseStats).to receive(:new)
        .and_raise(StandardError)
      expect { described_class.new }.to raise_error(StandardError)
      expect(Raven).to have_received(:capture_message)
    end
  end
end
