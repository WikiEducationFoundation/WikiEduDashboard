# frozen_string_literal: true

require 'rails_helper'

describe AcceptCourseApplication do
  let(:course) { create(:fellows_cohort, end: 2.months.from_now) }
  let(:user) { create(:user) }
  let(:staff) { create(:admin) }
  let(:application) { CourseApplication.create!(course:, user:) }
  let(:question_group) { create(:question_group) }

  before do
    CourseApplicationForm.create!(course:, open: true, question_group_ids: [question_group.id])
  end

  def accept
    described_class.new(application:, staff:)
  end

  def student?
    CoursesUsers.exists?(course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  context 'when the course is approved' do
    before { course.campaigns << create(:campaign) }

    it 'accepts the application and enrolls the applicant, past the application check' do
      acceptance = accept
      expect(acceptance).to be_success
      expect(application.reload).to be_accepted
      expect(application.decided_by).to eq(staff)
      expect(application.decided_at).to be_present
      expect(student?).to be(true)
    end

    it 'accepts a declined application' do
      application.update!(status: :declined)
      accept
      expect(application.reload).to be_accepted
      expect(student?).to be(true)
    end

    it 'accepts someone an admin already added to the course' do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      expect(accept).to be_success
      expect(application.reload).to be_accepted
    end

    it 'leaves an accepted application as it was' do
      application.update!(status: :accepted, decided_by: user, decided_at: 1.day.ago)
      expect(accept).to be_success
      expect(application.reload.decided_by).to eq(user)
      expect(student?).to be(false)
    end
  end

  context 'when the course is not yet approved' do
    it 'changes nothing and gives the reason' do
      acceptance = accept
      expect(acceptance).not_to be_success
      expect(acceptance.failure).to eq('not_yet_approved')
      expect(application.reload).to be_submitted
      expect(student?).to be(false)
    end
  end
end
