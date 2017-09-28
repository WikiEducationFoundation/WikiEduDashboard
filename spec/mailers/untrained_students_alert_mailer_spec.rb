# frozen_string_literal: true

require 'rails_helper'

describe UntrainedStudentsAlertMailer do
  let(:course) { create(:course) }
  let(:instructor) { create(:user, email: 'instructor@wikiedu.org') }
  let!(:courses_user) do
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end
  let(:content_expert) { create(:user, username: 'ce', permissions: 1, email: 'ce@wikiedu.org') }
  let!(:courses_user2) do
    create(:courses_user, course_id: course.id, user_id: content_expert.id,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end
  let(:alert) do
    create(:alert, type: 'UntrainedStudentsAlert', course_id: course.id)
    Alert.last
  end

  describe '.email' do
    let(:mail) { described_class.email(alert) }
    it 'delivers an email to the instructor and CCs Wiki Ed staff' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to include(course.slug)
      expect(mail.to).to include(instructor.email)
      expect(mail.cc).to include(content_expert.email)
    end
  end
end
