# frozen_string_literal: true

require 'rails_helper'

describe LtiSession do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:api_key) { 'k' }
  let(:ltik) { 'l' }
  let(:idtoken_url) { "https://#{domain}/api/idtoken" }

  let(:idtoken) do
    {
      'user' => {
        'id' => 'lti-user-1',
        'name' => 'Jane Doe',
        'email' => 'jane@example.edu',
        'roles' => [
          'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'
        ]
      },
      'platform' => {
        'id' => 'platform-x',
        'productFamilyCode' => 'canvas'
      },
      'launch' => {
        'context' => {
          'id' => 'canvas-course-77',
          'title' => 'WRIT 2010'
        },
        'resourceLink' => {
          'id' => 'rl-99'
        }
      },
      'services' => {
        'namesAndRoles' => {
          'contextMembershipsUrl' =>
            'https://canvas.example.com/api/lti/courses/1/names_and_roles'
        },
        'assignmentAndGrades' => {
          'available' => true,
          'lineItemsUrl' =>
            'https://canvas.example.com/api/lti/courses/1/line_items'
        }
      }
    }
  end

  before do
    stub_request(:get, idtoken_url)
      .to_return(status: 200, body: idtoken.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  subject(:lti_session) { described_class.new(domain, api_key, ltik) }

  describe 'launch context accessors' do
    it 'exposes user identity, role, platform, and context fields' do
      expect(lti_session.user_lti_id).to eq('lti-user-1')
      expect(lti_session.user_name).to eq('Jane Doe')
      expect(lti_session.user_email).to eq('jane@example.edu')
      expect(lti_session.lms_id).to eq('platform-x')
      expect(lti_session.lms_family).to eq('canvas')
      expect(lti_session.lms_context_id).to eq('canvas-course-77')
      expect(lti_session.lms_resource_link_id).to eq('rl-99')
      expect(lti_session.context_title).to eq('WRIT 2010')
      expect(lti_session.nrps_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/names_and_roles')
      expect(lti_session.ags_lineitems_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/line_items')
    end
  end

  describe '#instructor? / #student?' do
    it 'is instructor when role suffix matches' do
      expect(lti_session).to be_instructor
      expect(lti_session).not_to be_student
    end

    context 'with a learner role' do
      before do
        idtoken['user']['roles'] =
          ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner']
        stub_request(:get, idtoken_url)
          .to_return(status: 200, body: idtoken.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'is student' do
        expect(lti_session).to be_student
        expect(lti_session).not_to be_instructor
      end
    end
  end

  describe '#find_or_create_binding!' do
    it 'creates a binding the first time' do
      expect { lti_session.find_or_create_binding! }
        .to change(LtiCourseBinding, :count).by(1)

      binding = LtiCourseBinding.last
      expect(binding.lms_id).to eq('platform-x')
      expect(binding.lms_family).to eq('canvas')
      expect(binding.lms_context_id).to eq('canvas-course-77')
      expect(binding.lms_resource_link_id).to eq('rl-99')
      expect(binding.gradebook_granularity).to eq('lumped')
      expect(binding.nrps_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/names_and_roles')
      expect(binding.ags_lineitems_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/line_items')
    end

    it 'returns the existing binding on a subsequent launch' do
      first = lti_session.find_or_create_binding!
      second = described_class.new(domain, api_key, ltik).find_or_create_binding!

      expect(second.id).to eq(first.id)
      expect(LtiCourseBinding.count).to eq(1)
    end
  end

  describe '#link_lti_user' do
    let(:user) { create(:user) }

    it 'creates an LtiContext bound to the binding and user' do
      expect { lti_session.link_lti_user(user) }
        .to change(LtiContext, :count).by(1)

      ctx = LtiContext.last
      expect(ctx.user).to eq(user)
      expect(ctx.user_lti_id).to eq('lti-user-1')
      expect(ctx.lti_course_binding_id).to eq(LtiCourseBinding.last.id)
      expect(ctx.email).to eq('jane@example.edu')
      expect(ctx.name).to eq('Jane Doe')
      expect(ctx.roles).to include(
        'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'
      )
      expect(ctx.linked_at).to be_present
    end

    it 'is idempotent across repeated launches' do
      lti_session.link_lti_user(user)
      expect { described_class.new(domain, api_key, ltik).link_lti_user(user) }
        .not_to change(LtiContext, :count)
    end

    it 'links a previously-unlinked NRPS-discovered context to a user' do
      binding = lti_session.find_or_create_binding!
      pre = LtiContext.create!(user_lti_id: 'lti-user-1',
                               lti_course_binding: binding,
                               lms_id: 'platform-x',
                               email: 'old@example.edu')

      ctx = lti_session.link_lti_user(user)

      expect(ctx.id).to eq(pre.id)
      expect(ctx.user).to eq(user)
      expect(ctx.linked_at).to be_present
      expect(ctx.email).to eq('jane@example.edu')
    end

    it 'does not POST any grade signal during linking' do
      stub_request(:post, /api\/lineitems/).to_return(status: 500)
      lti_session.link_lti_user(user)
      expect(WebMock).not_to have_requested(:post, /api\/lineitems/)
    end
  end
end
