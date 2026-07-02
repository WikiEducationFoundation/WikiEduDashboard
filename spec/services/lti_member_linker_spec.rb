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

  let(:learner_member) do
    {
      user_lti_id: 'lti-1',
      name: 'Alice Doe',
      email: 'alice@example.edu',
      given_name: 'Alice', family_name: 'Doe', picture: nil,
      roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
      status: 'Active'
    }
  end

  let(:instructor_member) do
    {
      user_lti_id: 'lti-2',
      name: 'Pat Prof',
      email: 'pat@example.edu',
      given_name: 'Pat', family_name: 'Prof', picture: nil,
      roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'],
      status: 'Active'
    }
  end

  describe 'a member with no matching dashboard user' do
    it 'creates an unlinked LtiContext (deferred linking)' do
      expect { described_class.new(binding, learner_member) }
        .to change(LtiContext, :count).by(1)
      ctx = LtiContext.last
      expect(ctx.user_id).to be_nil
      expect(ctx.linked_at).to be_nil
      expect(ctx.email).to eq('alice@example.edu')
      expect(ctx.roles).to include(/Learner/)
    end

    it 'does not enroll anyone' do
      expect { described_class.new(binding, learner_member) }
        .not_to change(CoursesUsers, :count)
    end
  end

  describe 'a member with a matching dashboard user (case-insensitive email)' do
    let!(:user) { create(:user, email: 'Alice@Example.edu') }

    it 'auto-links and enrolls as a student' do
      expect { described_class.new(binding, learner_member) }
        .to change(CoursesUsers, :count).by(1)
      ctx = LtiContext.find_by(user_lti_id: 'lti-1')
      expect(ctx.user).to eq(user)
      expect(ctx.linked_at).to be_present
      cu = CoursesUsers.find_by(user: user, course: course)
      expect(cu.role).to eq(CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'auto-links and enrolls as an instructor when role is Instructor' do
      pat = create(:user, username: 'Pat', email: 'pat@example.edu')
      expect { described_class.new(binding, instructor_member) }
        .to change(CoursesUsers, :count).by(1)
      cu = CoursesUsers.find_by(user: pat, course: course)
      expect(cu.role).to eq(CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
  end

  describe 'idempotency' do
    let!(:user) { create(:user, email: 'alice@example.edu') }

    it 'does not duplicate the LtiContext on a second call' do
      described_class.new(binding, learner_member)
      expect { described_class.new(binding, learner_member) }
        .not_to change(LtiContext, :count)
    end

    it 'does not double-enroll on a second call' do
      described_class.new(binding, learner_member)
      expect { described_class.new(binding, learner_member) }
        .not_to change(CoursesUsers, :count)
    end
  end

  describe 'a binding with no course' do
    let(:binding) do
      LtiCourseBinding.create!(
        lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
    end
    let!(:user) { create(:user, email: 'alice@example.edu') }

    it 'links the LtiContext but does not enroll (no course bound yet)' do
      starting_courses_users_count = CoursesUsers.count
      expect { described_class.new(binding, learner_member) }
        .to change(LtiContext, :count).by(1)
      expect(CoursesUsers.count).to eq(starting_courses_users_count)
      expect(LtiContext.last.user).to eq(user)
    end
  end
end
