# frozen_string_literal: true

require 'rails_helper'

describe InstructorRosterContext do
  let(:course) { create(:course, slug: 'School/Course_(Term)') }
  let(:binding) do
    LtiCourseBinding.create!(course:, lms_id: 'canvas-guid', lms_family: 'canvas',
                             lms_context_id: 'ctx-11', lms_resource_link_id: 'rl-11',
                             lti_version: '1.2.0')
  end
  let(:launched) { create(:user, username: 'Zoe_Launched') }
  let(:passcode) { create(:user, username: 'adam_Passcode') }
  let(:instructor) { create(:user, username: 'Prof') }

  subject(:roster) { described_class.new(binding:) }

  before do
    CoursesUsers.create!(course:, user: launched, role: CoursesUsers::Roles::STUDENT_ROLE,
                         revision_count: 12, character_sum_ms: 3400, references_count: 5)
    CoursesUsers.create!(course:, user: passcode, role: CoursesUsers::Roles::STUDENT_ROLE)
    CoursesUsers.create!(course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    LtiContext.create!(user: launched, lti_course_binding: binding, user_lti_id: 'lti-zoe',
                       lms_id: 'canvas-guid', roles: ['Learner'], linked_at: 1.hour.ago)
    LtiContext.create!(user: instructor, lti_course_binding: binding, user_lti_id: 'lti-prof',
                       lms_id: 'canvas-guid', roles: ['Instructor'], linked_at: 2.hours.ago)
  end

  it 'lists every enrolled student, sorted by username regardless of case' do
    expect(roster.rows.map(&:username)).to eq(%w[adam_Passcode Zoe_Launched])
  end

  it 'leaves the instructor out' do
    expect(roster.rows.map(&:username)).not_to include('Prof')
  end

  # Enrollment is the basis, not launches: the passcode student is listed, and
  # only the one with a linked launch context is marked connected.
  it 'marks the student who launched from Canvas and not the one who joined by passcode' do
    expect(roster.rows.map(&:connected)).to eq([false, true])
  end

  it 'carries the edit statistics from the course roster' do
    zoe = roster.rows.last
    expect([zoe.revision_count, zoe.character_sum_ms, zoe.references_count]).to eq([12, 3400, 5])
  end

  it 'links to the student details page' do
    expect(roster.rows.first.details_url)
      .to eq('/courses/School/Course_(Term)/students/articles/adam_Passcode')
  end

  it 'builds the same overview a student sees, and their peer-review progress' do
    zoe = roster.rows.last
    expect(zoe.status).to be_a(StudentStatusContext)
    expect(zoe.status.user).to eq(launched)
    expect(zoe.peer_review_progress).to be_a(LtiPeerReviewProgress)
    expect(zoe.peer_reviews).to eq([])
  end

  it 'is empty for a course with no students' do
    CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).delete_all
    expect(roster).to be_empty
  end
end
