# frozen_string_literal: true

require 'rails_helper'

describe UnsubmittedCourseAlertMailer do
  describe '#send_email' do
    let(:classroom_program_manager) { create(:user, username: 'CPM', email: 'cpm@wikiedu.org') }
    let(:course) { create(:course) }
    let(:alert) { create(:unsubmitted_course_alert, user: instructor, course:) }
    let(:mail) { described_class.send_email(alert) }

    before do
      users = Setting.find_or_create_by(key: 'special_users')
      users.update value: { classroom_program_manager: classroom_program_manager.username }
    end

    context 'user with a real name' do
      let(:instructor) { create(:instructor, real_name: 'Ada L.', email: 'ada@gmail.com') }

      it 'sends an email to the course instructor' do
        subject = 'Reminder: Submit your Wiki Education course page'
        expect(mail.subject).to eq(subject)
        expect(mail.to).to eq([instructor.email])
        expect(mail.html_part.body).to include(instructor.real_name)
      end
    end

    context 'user with only a username' do
      let(:instructor) { create(:instructor, email: 'ada@gmail.com') }

      it 'sends an email to the course instructor' do
        subject = 'Reminder: Submit your Wiki Education course page'
        expect(mail.subject).to eq(subject)
        expect(mail.to).to eq([instructor.email])
        expect(mail.html_part.body).to include(instructor.username)
      end
    end
  end
end
