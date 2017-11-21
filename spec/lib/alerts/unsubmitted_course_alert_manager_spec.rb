# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/unsubmitted_course_alert_manager"

describe UnsubmittedCourseAlertManager do
  let(:subject) { UnsubmittedCourseAlertManager.new }
  let(:classroom_program_manager) { create(:user, username: 'CPM', email: 'cpm@wikiedu.org') }
  let(:outreach_manager) { create(:user, username: 'OM', email: 'om@wikiedu.org') }

  before do
    users = Setting.find_or_create_by(key: 'special_users')
    users.update value: { classroom_program_manager: classroom_program_manager.username,
                          outreach_manager: outreach_manager.username }

    @first_course = create(:course, submitted: false, start: 1.week.ago)
    @first_course.tags << Tag.new(tag: 'first_time_instructor')

    @returing_course = create(:course, submitted: false, slug: 'returning', start: 1.week.ago)
    @returing_course.tags << Tag.new(tag: 'returning_instructor')

    create(:course, submitted: false, start: 1.week.from_now, slug: 'not_started')
  end

  context 'when the alerts do not exist' do
    it 'creates alerts for started courses and sends emails' do
      subject.create_alerts
      expect(Alert.count).to eq(2)
    end
  end

  context 'when alerts already exist' do
    before { create(:alert, type: 'UnsubmittedCourseAlert', course: @first_course) }
    before { create(:alert, type: 'UnsubmittedCourseAlert', course: @returing_course) }

    it 'does not create new ones' do
      expect(Alert.count).to eq(2)
      subject.create_alerts
      expect(Alert.count).to eq(2)
    end
  end
end
