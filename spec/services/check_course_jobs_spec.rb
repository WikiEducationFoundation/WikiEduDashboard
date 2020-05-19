# frozen_string_literal: true

require 'rails_helper'

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
    it 'runs without error' do
      subject.find_job
    end
  end

  describe '#delete_unique_lock' do
    it 'runs without error' do
      subject.delete_unique_lock
    end
  end
end
