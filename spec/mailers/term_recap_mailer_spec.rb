# frozen_string_literal: true

require 'rails_helper'

describe TermRecapMailer do
  let(:campaign) { create(:campaign, slug: 'fall_2026') }
  let(:instructor) { create(:user, username: 'Instructor', email: 'instructor@example.edu') }
  let(:course) do
    create(:course, slug: 'school/public_course', character_sum: 10_350, campaigns: [campaign])
  end
  let(:private_course) do
    create(:course, slug: 'school/private_course', private: true, character_sum: 51_750,
                    campaigns: [campaign])
  end

  def enroll(course, username)
    user = User.find_by(username:) || create(:user, username:)
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  before do
    create(:courses_user, course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    enroll(course, 'StudentA')
    enroll(course, 'StudentB')
    enroll(private_course, 'StudentB')
    enroll(private_course, 'StudentC')
  end

  # The cohort sentence's word count leaves out private courses, so its
  # course and student counts have to as well.
  %i[email basic_email].each do |email_type|
    it "leaves private courses out of the whole cohort sentence in #{email_type}" do
      body = described_class.send(email_type, course, campaign).body.encoded
      expect(body).to include('cohort of 1 courses')
      expect(body).to match(/whose\s+2 students\s+contributed\s+2K words/)
    end
  end
end
