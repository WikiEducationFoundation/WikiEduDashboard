# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/alerts/sandboxed_course_mainspace_monitor')

def mock_mailer
  OpenStruct.new(deliver_now: true)
end

describe SandboxedCourseMainspaceMonitor do
  describe '.create_alerts_for_active_courses' do
    let(:course) do
      create(:course, start: 1.month.ago, end: 1.month.after, flags: { stay_in_sandbox: true })
    end

    let!(:inactive_course) do
      create(:course, slug: 'second/course', start: 1.month.ago, end: 1.month.after,
                      flags: { stay_in_sandbox: true })
    end

    # Article with substantial mainspace edits
    let(:article) { create(:article) }
    let(:chars_added) { 2062 }
    let!(:articles_course) do
      create(:articles_course, article:,
                               course:,
                               character_sum: chars_added)
    end

    it 'creates Alert records for active sandboxed courses' do
      expect(SandboxedCourseMainspaceAlert.count).to eq(0)
      described_class.create_alerts_for_active_courses
      expect(SandboxedCourseMainspaceAlert.count).to eq(1)
    end
  end
end
