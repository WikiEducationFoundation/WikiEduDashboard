# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/unsubmitted_course_alert_manager"

describe UnsubmittedCourseAlertManager do
  let(:subject) { described_class.new }

  before do
    # CPM must be created for email to be sent
    classroom_program_manager = create(:user, username: 'CPM', email: 'cpm@wikiedu.org')
    users = Setting.find_or_create_by(key: 'special_users')
    users.update value: { classroom_program_manager: classroom_program_manager.username }

    new_instructor = create(:instructor,
                            id: 99,
                            username: 'new',
                            email: 'new@wikiedu.org')
    returning_instructor = create(:instructor,
                                  id: 88,
                                  username: 'returning',
                                  email: 'returning@wikiedu.org')

    @first_course = create(:course,
                           instructors: [new_instructor],
                           submitted: false,
                           start: 3.days.from_now,
                           created_at: 3.weeks.ago)
    @first_course.tags << Tag.new(tag: 'first_time_instructor')
    create(:courses_user, course: @first_course, user: new_instructor, role: 1)

    @returning_course = create(:course,
                               instructors: [returning_instructor],
                               submitted: false,
                               slug: 'returning',
                               start: 3.days.from_now,
                               created_at: 3.weeks.ago)
    @returning_course.tags << Tag.new(tag: 'returning_instructor')
    create(:courses_user, course: @returning_course, user: returning_instructor, role: 1)

    create(:course, submitted: false, start: 1.week.ago, slug: 'already_started')
    create(:course, submitted: false, start: 1.week.from_now, slug: 'not_yet_started')
  end

  context 'when the alerts do not exist' do
    it 'creates alerts for courses that were created more than 2 weeks ago' do
      subject.create_alerts
      expect(Alert.count).to eq(2)
    end

    it 'sends the alert to the instructor on the course' do
      subject.create_alerts
      expect([Alert.first.user_id, Alert.last.user_id]).to include(99, 88)
    end

    it 'does not create alerts for courses that were created too recently' do
      create(:course,
             submitted: false,
             slug: 'last_minute_course',
             start: 3.days.from_now,
             created_at: 4.days.ago)
      subject.create_alerts
      expect(Alert.count).to eq(2)
    end
  end

  context 'when alerts already exist' do
    before do
      create(:alert, type: 'UnsubmittedCourseAlert', course: @first_course)
      create(:alert, type: 'UnsubmittedCourseAlert', course: @returning_course)
    end

    it 'does not create new ones' do
      expect(Alert.count).to eq(2)
      subject.create_alerts
      expect(Alert.count).to eq(2)
    end
  end
end
