# frozen_string_literal: true

require 'rails_helper'

describe EnrollInstructorAsLearner do
  let(:course) { create(:course, flags: { instructor_learner: true }) }
  let(:instructor) { create(:user) }

  before do
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  let(:subject) { described_class.new(course:, instructor:) }

  it 'enrolls the instructor with the student role' do
    subject
    expect(CoursesUsers.exists?(course:, user: instructor,
                                role: CoursesUsers::Roles::STUDENT_ROLE)).to be true
  end

  it 'keeps the existing instructor role' do
    subject
    expect(CoursesUsers.exists?(course:, user: instructor,
                                role: CoursesUsers::Roles::INSTRUCTOR_ROLE)).to be true
  end

  it 'succeeds even when the course is not yet approved' do
    expect(course.approved?).to be false
    expect(subject.result['success']).not_to be_nil
  end

  it 'is idempotent' do
    described_class.new(course:, instructor:)
    described_class.new(course:, instructor:)
    student_rows = CoursesUsers.where(course:, user: instructor,
                                      role: CoursesUsers::Roles::STUDENT_ROLE)
    expect(student_rows.count).to eq(1)
  end

  it 'does not post enrollment edits to the userpage' do
    expect(EnrollInCourseWorker).not_to receive(:schedule_edits)
    subject
  end

  it 'updates the cached student count' do
    subject
    expect(course.reload.user_count).to eq(1)
  end

  context 'when the course is withdrawn' do
    let(:course) { create(:course, withdrawn: true, flags: { instructor_learner: true }) }

    it 'does not enroll the instructor as a student' do
      expect(subject.result['failure']).to eq('withdrawn')
      expect(CoursesUsers.exists?(course:, user: instructor,
                                  role: CoursesUsers::Roles::STUDENT_ROLE)).to be false
    end
  end

  context 'when the instructor is a disallowed user' do
    before { DisallowedUsers.add_user(instructor.username) }

    it 'does not enroll the instructor as a student' do
      expect(subject.result['failure']).to eq('disallowed_user')
      expect(CoursesUsers.exists?(course:, user: instructor,
                                  role: CoursesUsers::Roles::STUDENT_ROLE)).to be false
    end
  end
end
