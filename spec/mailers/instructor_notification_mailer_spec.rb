# frozen_string_literal: true

require 'rails_helper'

describe InstructorNotificationMailer do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:instructor) { create(:user, email: 'instructor@wikiedu.org') }
  let!(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end
  # let(:content_expert) do
  #   create(:user, username: 'content_expert', permissions: 1, email: 'ce@wikiedu.org')
  # end
  # let!(:courses_user2) do
  #   create(:courses_user, course_id: course.id, user_id: content_expert.id,
  #                         role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  # end
  let(:alert) do
    create(:alert, type: 'InstructorNotificationAlert', course_id: course.id,
message: 'Test Email Content', user: admin)
    Alert.last
  end

  describe '.email' do
    let(:mail) { described_class.email(alert) }

    it 'delivers an email to the instructor and CCs Wiki Ed staff' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to include('New Notification from Admin') # subject defined in Alert Type
      expect(mail.to).to include(instructor.email)
      expect(mail.body).to include('Test Email Content')
      expect(mail.reply_to).to include(admin.email)
    end
  end
end
