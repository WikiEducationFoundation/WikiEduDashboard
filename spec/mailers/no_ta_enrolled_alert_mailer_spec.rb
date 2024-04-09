# frozen_string_literal: true

require 'rails_helper'

describe NoTaEnrolledAlertMailer do
  let(:course) { create(:course) }
  let(:instructor) { create(:user, email: 'instructor@wikiedu.org') }
  let!(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  let(:add_ta_alert) do
    create(:add_ta_alert, type: 'NoTaEnrolledAlert', course_id: course.id)
    Alert.last
  end

  describe '.email' do
    let(:mail) { described_class.email(add_ta_alert) }

    it 'delivers an email to the instructor reminding them to add another instructor' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to include(course.slug)
      expect(mail.to).to include(instructor.email)
    end
  end
end
