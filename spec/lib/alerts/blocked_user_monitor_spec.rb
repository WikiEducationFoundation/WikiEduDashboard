# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/alerts/blocked_user_monitor"

describe BlockedUserMonitor do
  describe '.create_alerts_for_recently_blocked_users' do
    let(:user) { create(:user, username: 'Verdantpowerinc', email: 'student@kiwi.com') }
    let(:instructor_1) { create(:user, username: 'Instructor1', email: 'nospan@nospam.com') }
    let(:instructor_2) { create(:user, username: 'Instructor2', email: 'instructor@course.com') }
    let(:staff) { create(:user, username: 'staff', email: 'staff@kiwi.com', greeter: true) }
    let(:course) do
      now = Time.zone.now
      create(:course, start: now.days_ago(7), end: now.days_since(7))
    end

    before do
      create(:courses_user, user:, course:)
      create(:courses_user, course:, user: instructor_1,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      create(:courses_user, course:, user: instructor_2,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      create(:courses_user, course:, user: staff,
            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      stub_block_log_query
    end

    it 'creates an Alert record for a blocked user' do
      expect { described_class.create_alerts_for_recently_blocked_users }
        .to change(BlockedUserAlert, :count).by(1)
    end

    it 'does not create multiple alerts for the same block' do
      expect do
        2.times { described_class.create_alerts_for_recently_blocked_users }
      end.to change(BlockedUserAlert, :count).by(1)
    end

    it 'uses the proper mailer' do
      expect(BlockedUserAlertMailer).to receive(:send_mails_to_concerned)
      described_class.create_alerts_for_recently_blocked_users
    end

    it 'sends a mail to staff, instructors & student' do
      expect do
        described_class.create_alerts_for_recently_blocked_users
      end.to change { BlockedUserAlertMailer.deliveries.count }.by(1)
      msg = BlockedUserAlertMailer.deliveries.first
      expect(msg.to).to match_array([instructor_1, instructor_2, user, staff].map(&:email))
    end
  end
end
