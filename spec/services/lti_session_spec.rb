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
        'productFamilyCode' => 'canvas',
        'url' => 'https://canvas.example.com'
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
        'serviceKey' => 'svc-key-from-launch',
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
      expect(lti_session.lms_id).to eq('platform-x')
      expect(lti_session.lms_family).to eq('canvas')
      expect(lti_session.lms_context_id).to eq('canvas-course-77')
      expect(lti_session.lms_resource_link_id).to eq('rl-99')
      expect(lti_session.context_title).to eq('WRIT 2010')
      expect(lti_session.platform_url).to eq('https://canvas.example.com')
      expect(lti_session.nrps_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/names_and_roles')
      expect(lti_session.ags_lineitems_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/line_items')
    end
  end

  describe '#deep_link_resource' do
    it 'is nil when the launch carries no resource marker' do
      expect(lti_session.deep_link_resource).to be_nil
    end

    it 'returns the custom resource marker when present' do
      idtoken['custom'] = { 'resource' => 'Block:42' }
      stub_request(:get, idtoken_url)
        .to_return(status: 200, body: idtoken.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      expect(lti_session.deep_link_resource).to eq('Block:42')
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

  # Pinned against Canvas's published enrollment → LTI 1.3 role table:
  # https://developerdocs.instructure.com/services/canvas/external-tools/file.canvas_roles
  # The classification is an allowlist in both directions, so a role Canvas adds
  # later lands in `unsupported_role?` rather than silently becoming a student.
  describe 'Canvas role classification' do
    def session_with(roles)
      idtoken['user']['roles'] = roles
      stub_request(:get, idtoken_url)
        .to_return(status: 200, body: idtoken.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      described_class.new(domain, api_key, ltik)
    end

    vocab = 'http://purl.imsglobal.org/vocab/lis/v2/membership'

    it 'treats a TeacherEnrollment as staff' do
      expect(session_with(["#{vocab}#Instructor"])).to be_instructor
    end

    # Canvas sends the base Instructor role alongside the sub-role for a TA, so
    # the base match is what classifies them — the sub-role string alone would
    # not match `membership#Instructor`.
    it 'treats a TaEnrollment as staff via the base Instructor role' do
      session = session_with(["#{vocab}#Instructor", "#{vocab}/Instructor#TeachingAssistant"])
      expect(session).to be_instructor
      expect(session).not_to be_unsupported_role
    end

    it 'treats a StudentEnrollment as a learner' do
      session = session_with(["#{vocab}#Learner"])
      expect(session).to be_student
      expect(session).not_to be_unsupported_role
    end

    # The escalation this allowlist exists to stop: Canvas maps
    # ObserverEnrollment to Mentor, which used to be in INSTRUCTOR_ROLES.
    it 'treats an ObserverEnrollment (Mentor) as neither staff nor learner' do
      session = session_with(["#{vocab}#Mentor"])
      expect(session).not_to be_instructor
      expect(session).not_to be_student
      expect(session).to be_unsupported_role
    end

    it 'treats a DesignerEnrollment (ContentDeveloper) as neither' do
      session = session_with(["#{vocab}#ContentDeveloper"])
      expect(session).not_to be_instructor
      expect(session).not_to be_student
      expect(session).to be_unsupported_role
    end

    it 'treats an unrecognized role as neither' do
      session = session_with(["#{vocab}#Officer"])
      expect(session).to be_unsupported_role
    end

    it 'treats a launch with no roles as neither' do
      session = session_with([])
      expect(session).not_to be_student
      expect(session).to be_unsupported_role
    end

    it 'lets staff win when a launch carries both roles' do
      session = session_with(["#{vocab}#Learner", "#{vocab}#Instructor"])
      expect(session).to be_instructor
      expect(session).not_to be_student
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
      expect(binding.nrps_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/names_and_roles')
      expect(binding.ags_lineitems_url)
        .to eq('https://canvas.example.com/api/lti/courses/1/line_items')
      expect(binding.lms_context_title).to eq('WRIT 2010')
      expect(binding.lms_platform_url).to eq('https://canvas.example.com')
    end

    it 'returns the existing binding on a subsequent launch' do
      first = lti_session.find_or_create_binding!
      second = described_class.new(domain, api_key, ltik).find_or_create_binding!

      expect(second.id).to eq(first.id)
      expect(LtiCourseBinding.count).to eq(1)
    end

    it 'captures the serviceKey from the idtoken onto the binding' do
      binding = lti_session.find_or_create_binding!
      expect(binding.ltiaas_service_credentials).to eq('svc-key-from-launch')
    end

    it 'refreshes the serviceKey on every launch' do
      lti_session.find_or_create_binding!
      idtoken['services']['serviceKey'] = 'svc-key-rotated'
      stub_request(:get, idtoken_url)
        .to_return(status: 200, body: idtoken.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      binding = described_class.new(domain, api_key, ltik).find_or_create_binding!
      expect(binding.ltiaas_service_credentials).to eq('svc-key-rotated')
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
      # Anonymized: no name/email is stored (columns removed).
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
                               lms_id: 'platform-x')

      ctx = lti_session.link_lti_user(user)

      expect(ctx.id).to eq(pre.id)
      expect(ctx.user).to eq(user)
      expect(ctx.linked_at).to be_present
    end

    it 'does not POST any grade signal during linking' do
      stub_request(:post, /api\/lineitems/).to_return(status: 500)
      lti_session.link_lti_user(user)
      expect(WebMock).not_to have_requested(:post, /api\/lineitems/)
    end

    # Both directions of the map have to be 1:1 within a course. Two Canvas
    # members resolving to one Wikipedia account would make grade sync post the
    # same progress at both of their gradebook rows.
    context 'when the Dashboard user is already linked to another LMS identity' do
      let(:binding) { lti_session.find_or_create_binding! }

      before do
        LtiContext.create!(user_lti_id: 'lti-someone-else', lti_course_binding: binding,
                           lms_id: 'platform-x', user:, linked_at: 1.day.ago)
      end

      it 'refuses the second link' do
        expect { described_class.new(domain, api_key, ltik).link_lti_user(user) }
          .to raise_error(LtiSession::ConflictingLinkError)
      end

      it 'leaves the first link intact' do
        expect { described_class.new(domain, api_key, ltik).link_lti_user(user) }
          .to raise_error(LtiSession::ConflictingLinkError)
        expect(LtiContext.find_by(user_lti_id: 'lti-someone-else').user).to eq(user)
      end

      it 'still allows the same identity to relaunch as the same user' do
        other = create(:user, username: 'Someone Else')
        ctx = lti_session.link_lti_user(other)
        expect { described_class.new(domain, api_key, ltik).link_lti_user(other) }
          .not_to raise_error
        expect(ctx.reload.user).to eq(other)
      end
    end

    # The ltik travels in the URL, so if a launch could move an LMS identity onto
    # whoever is currently signed in, a student could hand their launch link to
    # someone else and have that person's Dashboard progress feed the student's
    # own Canvas grade.
    describe 'when the LMS identity already belongs to a different Dashboard user' do
      let(:other) { create(:user, username: 'Someone Else') }

      before { lti_session.link_lti_user(user) }

      it 'refuses to move the link' do
        expect { described_class.new(domain, api_key, ltik).link_lti_user(other) }
          .to raise_error(LtiSession::ConflictingLinkError)
      end

      it 'leaves the original link in place' do
        expect { described_class.new(domain, api_key, ltik).link_lti_user(other) }
          .to raise_error(LtiSession::ConflictingLinkError)
        expect(LtiContext.find_by(user_lti_id: 'lti-user-1').user).to eq(user)
      end

      it 'creates no second context for the same identity' do
        expect do
          described_class.new(domain, api_key, ltik).link_lti_user(other)
        rescue LtiSession::ConflictingLinkError
          nil
        end.not_to change(LtiContext, :count)
      end
    end
  end
end
