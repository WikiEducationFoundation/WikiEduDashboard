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
end
