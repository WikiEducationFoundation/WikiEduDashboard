# frozen_string_literal: true

require 'rails_helper'

describe LtiMemberLinker do
  let(:course) do
    create(:course).tap { |c| c.campaigns << Campaign.first }
  end
  let(:binding) do
    LtiCourseBinding.create!(
      course: course,
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end

  # Anonymized posture: NRPS members carry only the opaque id, roles, and
  # status — no names or emails.
  let(:learner_member) do
    { user_lti_id: 'lti-1',
      roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
      status: 'Active' }
  end

  describe 'a member who has not linked a Wikipedia account' do
    # Even if a dashboard user with a matching email exists, there is no
    # email-based auto-linking — we never receive the member's email.
    let!(:user) { create(:user, email: 'someone@example.edu') }

    it 'records a deferred, unlinked LtiContext (roles only, no auto-link)' do
      expect { described_class.new(binding, learner_member) }
        .to change(LtiContext, :count).by(1)
      ctx = LtiContext.find_by(user_lti_id: 'lti-1')
      expect(ctx.user_id).to be_nil
      expect(ctx.linked_at).to be_nil
      expect(ctx.roles).to include(/Learner/)
    end

    it 'does not enroll anyone' do
      expect { described_class.new(binding, learner_member) }
        .not_to change(CoursesUsers, :count)
    end
  end

  describe 'a member already linked via a prior Wikipedia OAuth launch' do
    let!(:user) { create(:user, username: 'Alice') }

    before do
      LtiContext.create!(user: user, lti_course_binding: binding,
                         user_lti_id: 'lti-1', lms_id: 'platform-x',
                         roles: ['stale'], linked_at: 1.day.ago)
    end

    it 'refreshes roles and ensures a student enrollment' do
      expect { described_class.new(binding, learner_member) }
        .to change(CoursesUsers, :count).by(1)
      ctx = LtiContext.find_by(user_lti_id: 'lti-1')
      expect(ctx.roles).to include(/Learner/)
      cu = CoursesUsers.find_by(user: user, course: course)
      expect(cu.role).to eq(CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'enrolls as an instructor when the LMS role is Instructor' do
      instructor_member = learner_member.merge(
        roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor']
      )
      expect { described_class.new(binding, instructor_member) }
        .to change(CoursesUsers, :count).by(1)
      cu = CoursesUsers.find_by(user: user, course: course)
      expect(cu.role).to eq(CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  describe 'idempotency' do
    it 'does not duplicate the LtiContext on a second call' do
      described_class.new(binding, learner_member)
      expect { described_class.new(binding, learner_member) }
        .not_to change(LtiContext, :count)
    end
  end

  # JoinCourse refuses any second enrollment on a Wiki Ed course, so routing a
  # role change through it silently no-ops and the LMS role change never lands.
  describe 'role transitions' do
    let!(:user) { create(:user, username: 'Alice') }
    let(:instructor_member) do
      learner_member.merge(
        roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor']
      )
    end

    before do
      LtiContext.create!(user: user, lti_course_binding: binding,
                         user_lti_id: 'lti-1', lms_id: 'platform-x',
                         roles: ['stale'], linked_at: 1.day.ago)
    end

    def dashboard_role
      CoursesUsers.find_by(user:, course:).role
    end

    it 'promotes an existing student when the LMS makes them course staff' do
      CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      described_class.new(binding, instructor_member)
      expect(dashboard_role).to eq(CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'does not add a second enrollment when promoting' do
      CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      expect { described_class.new(binding, instructor_member) }
        .not_to change(CoursesUsers, :count)
    end

    # Deliberate: Canvas co-instructors are often TAs, which doesn't map to an
    # instructor role here, so demoting on that basis would lock the person who
    # set the course up out of it.
    it 'leaves an existing instructor alone when the LMS role is Learner' do
      CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      described_class.new(binding, learner_member)
      expect(dashboard_role).to eq(CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  # Canvas maps ObserverEnrollment to Mentor, which used to be in
  # INSTRUCTOR_ROLES — so an observer who connected a Wikipedia account was
  # enrolled as a Dashboard *instructor* on the course, and (once role promotion
  # landed) an observer already enrolled as a student was promoted into one.
  describe 'a Canvas member who is neither staff nor learner' do
    let!(:user) { create(:user, username: 'Observer') }
    let(:vocab) { 'http://purl.imsglobal.org/vocab/lis/v2/membership' }

    before do
      LtiContext.create!(user: user, lti_course_binding: binding,
                         user_lti_id: 'lti-1', lms_id: 'platform-x',
                         linked_at: 1.day.ago)
    end

    def link(role_suffix)
      described_class.new(binding, learner_member.merge(roles: ["#{vocab}##{role_suffix}"]))
    end

    it 'does not enroll an observer at all' do
      expect { link('Mentor') }.not_to change(CoursesUsers, :count)
    end

    it 'does not enroll a designer at all' do
      expect { link('ContentDeveloper') }.not_to change(CoursesUsers, :count)
    end

    it 'does not promote an observer who is already a student' do
      CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      link('Mentor')
      expect(CoursesUsers.find_by(user:, course:).role)
        .to eq(CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'still records the membership so the roster reflects Canvas' do
      link('Mentor')
      expect(LtiContext.find_by(user_lti_id: 'lti-1').roles).to include(/Mentor/)
    end

    # A TA carries the base Instructor role, so they are staff.
    it 'enrolls a teaching assistant as an instructor' do
      described_class.new(binding, learner_member.merge(
                                     roles: ["#{vocab}#Instructor",
                                             "#{vocab}/Instructor#TeachingAssistant"]
                                   ))
      expect(CoursesUsers.find_by(user:, course:).role)
        .to eq(CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  # No auto-disenrollment, but nothing should newly join a course on behalf of
  # someone Canvas has already removed from it.
  describe 'a member Canvas has deleted from the course' do
    let!(:user) { create(:user, username: 'Alice') }
    let(:deleted_member) { learner_member.merge(status: 'Deleted') }

    before do
      LtiContext.create!(user: user, lti_course_binding: binding,
                         user_lti_id: 'lti-1', lms_id: 'platform-x',
                         linked_at: 1.day.ago)
    end

    it 'does not enroll them' do
      expect { described_class.new(binding, deleted_member) }
        .not_to change(CoursesUsers, :count)
    end

    it 'still records the membership so the roster reflects Canvas' do
      described_class.new(binding, deleted_member)
      expect(LtiContext.find_by(user_lti_id: 'lti-1').roles).to include(/Learner/)
    end

    it 'leaves an enrollment they already had in place' do
      CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      described_class.new(binding, deleted_member)
      expect(CoursesUsers.exists?(user:, course:)).to be true
    end
  end
end
