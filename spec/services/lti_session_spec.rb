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

  # LTIAAS reports a legacy LTI 1.1 launch as ltiVersion "1.2.0", so legacy is
  # "not 1.3" rather than a string match on "1.1". A missing version reads as
  # 1.3: it is absent from every pre-legacy fixture and payload, and treating
  # its absence as legacy would start refusing production launches.
  describe '#lti_version / #legacy?' do
    def session_with_version(version)
      version.nil? ? idtoken.delete('ltiVersion') : idtoken['ltiVersion'] = version
      stub_request(:get, idtoken_url)
        .to_return(status: 200, body: idtoken.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      described_class.new(domain, api_key, ltik)
    end

    it 'is a 1.3 launch when the idtoken says so' do
      session = session_with_version('1.3.0')
      expect(session.lti_version).to eq('1.3.0')
      expect(session).not_to be_legacy
    end

    it 'reads a missing version as 1.3' do
      session = session_with_version(nil)
      expect(session.lti_version).to eq('1.3.0')
      expect(session).not_to be_legacy
    end

    it 'is legacy for the "1.2.0" LTIAAS reports on an LTI 1.1 launch' do
      session = session_with_version('1.2.0')
      expect(session.lti_version).to eq('1.2.0')
      expect(session).to be_legacy
    end

    it 'is legacy for any other non-1.3 version' do
      expect(session_with_version('1.1.0')).to be_legacy
    end
  end

  # The LTI 1.1 role vocabulary, as Canvas sends it for a legacy launch (per its
  # published role table) and as LTIAAS may hand it through unnormalized. Exact
  # matches: the institution- and system-level URNs must not classify like the
  # context roles, mirroring the 1.3 table's treatment of `institution/person#…`.
  describe 'LTI 1.1 role classification' do
    def session_with(roles)
      idtoken['ltiVersion'] = '1.2.0'
      idtoken['user']['roles'] = roles
      stub_request(:get, idtoken_url)
        .to_return(status: 200, body: idtoken.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      described_class.new(domain, api_key, ltik)
    end

    it 'treats the bare Instructor short name as staff' do
      session = session_with(['Instructor'])
      expect(session).to be_instructor
      expect(session).not_to be_student
    end

    it 'treats the Instructor context-role URN as staff' do
      expect(session_with(['urn:lti:role:ims/lis/Instructor'])).to be_instructor
    end

    it 'treats the bare Learner short name as a learner' do
      session = session_with(['Learner'])
      expect(session).to be_student
      expect(session).not_to be_instructor
      expect(session).not_to be_unsupported_role
    end

    it 'treats the Learner context-role URN as a learner' do
      expect(session_with(['urn:lti:role:ims/lis/Learner'])).to be_student
    end

    # Canvas's 1.1 TaEnrollment sends only the TA role, where 1.3 sends the base
    # Instructor role alongside it; a TA has to classify as staff under both.
    it 'treats a TaEnrollment (TeachingAssistant URN alone) as staff' do
      session = session_with(['urn:lti:role:ims/lis/TeachingAssistant'])
      expect(session).to be_instructor
      expect(session).not_to be_unsupported_role
    end

    it 'treats the Administrator context role as staff' do
      expect(session_with(['urn:lti:role:ims/lis/Administrator'])).to be_instructor
    end

    # The 1.1 shape of the observer escalation the 1.3 allowlist exists to stop:
    # Canvas's ObserverEnrollment sends Mentor plus the institution Observer role.
    it 'treats an ObserverEnrollment (Mentor + Observer) as neither staff nor learner' do
      session = session_with(['urn:lti:instrole:ims/lis/Observer',
                              'urn:lti:role:ims/lis/Mentor'])
      expect(session).not_to be_instructor
      expect(session).not_to be_student
      expect(session).to be_unsupported_role
    end

    it 'treats the bare Mentor short name as neither' do
      expect(session_with(['Mentor'])).to be_unsupported_role
    end

    it 'treats a DesignerEnrollment (ContentDeveloper) as neither' do
      expect(session_with(['ContentDeveloper'])).to be_unsupported_role
    end

    # Institution- and system-level roles are not course roles. The 1.3 table
    # doesn't accept `institution/person#Instructor`; the 1.1 table doesn't
    # accept its `instrole` counterpart, and suffix-matching on "Instructor"
    # would have.
    it 'does not treat institution-level Instructor or Administrator as staff' do
      expect(session_with(['urn:lti:instrole:ims/lis/Instructor'])).to be_unsupported_role
      expect(session_with(['urn:lti:instrole:ims/lis/Administrator'])).to be_unsupported_role
    end

    it 'does not treat a system administrator as staff' do
      expect(session_with(['urn:lti:sysrole:ims/lis/SysAdmin'])).to be_unsupported_role
    end

    # Fail closed on the sub-role forms nobody has seen Canvas send.
    it 'treats an unlisted sub-role as neither' do
      expect(session_with(['urn:lti:role:ims/lis/Instructor/PrimaryInstructor']))
        .to be_unsupported_role
    end

    it 'lets staff win when a launch carries both 1.1 roles' do
      session = session_with(%w[Learner Instructor])
      expect(session).to be_instructor
      expect(session).not_to be_student
    end

    it 'classifies a 1.3 role the same way on a legacy launch (LTIAAS may normalize)' do
      session = session_with(['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'])
      expect(session).to be_student
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

    it 'records the launch LTI version, 1.3 by default' do
      expect(lti_session.find_or_create_binding!.lti_version).to eq('1.3.0')
    end

    # The 1.1 idtoken shape LTIAAS documents: ltiVersion "1.2.0", a per-user
    # `legacyServiceKey` for Basic Outcomes, and no NRPS/AGS URLs.
    context 'for a legacy (LTI 1.1) launch' do
      before do
        idtoken['ltiVersion'] = '1.2.0'
        idtoken['services'] = { 'outcomes' => { 'available' => true },
                                'legacyServiceKey' => 'legacy-key-for-this-user',
                                'serviceKey' => 'svc-key-if-any' }
        stub_request(:get, idtoken_url)
          .to_return(status: 200, body: idtoken.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'records "1.2.0" on the binding' do
        binding = lti_session.find_or_create_binding!
        expect(binding.lti_version).to eq('1.2.0')
        expect(binding).to be_legacy
      end

      # Nothing in `ltiaas_service_credentials` for a binding with no services:
      # the legacy key is per-user and outcomes-only, and a 1.3 service key on a
      # 1.1 launch has nothing to authenticate.
      it 'persists no service credentials' do
        binding = lti_session.find_or_create_binding!
        expect(binding.ltiaas_service_credentials).to be_nil
        expect(binding.nrps_url).to be_nil
        expect(binding.ags_lineitems_url).to be_nil
      end

      # A course that moves from a 1.1 install to a 1.3 one refreshes its row on
      # the next 1.3 launch, like every other snapshot field.
      it 'refreshes the version when a later launch is 1.3' do
        lti_session.find_or_create_binding!
        idtoken['ltiVersion'] = '1.3.0'
        stub_request(:get, idtoken_url)
          .to_return(status: 200, body: idtoken.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        binding = described_class.new(domain, api_key, ltik).find_or_create_binding!
        expect(binding.lti_version).to eq('1.3.0')
      end
    end

    # find-then-create is not atomic. Two first launches from one Canvas course
    # can both find no row, and the unique index then makes one save raise — a
    # 500 inside the Canvas iframe for whichever instructor lost. The error here
    # is the real one from the real index: the first lookup is forced to return
    # an unsaved record even though the winner's row already exists.
    describe 'when a concurrent launch creates the binding first' do
      let(:winner) do
        LtiCourseBinding.create!(lms_id: 'platform-x', lms_context_id: 'canvas-course-77',
                                 lms_resource_link_id: 'rl-1')
      end

      before do
        winner
        calls = 0
        allow(LtiCourseBinding).to receive(:find_or_initialize_by)
          .and_wrap_original do |orig, *args|
            calls += 1
            calls == 1 ? LtiCourseBinding.new(**args.first) : orig.call(*args)
          end
      end

      it 'returns the winning row instead of raising' do
        expect(lti_session.find_or_create_binding!.id).to eq(winner.id)
      end

      it 'creates no second binding' do
        expect { lti_session.find_or_create_binding! }
          .not_to change(LtiCourseBinding, :count)
      end

      it 'still refreshes the launch snapshot onto it' do
        expect(lti_session.find_or_create_binding!.lms_resource_link_id).to eq('rl-99')
      end

      # One retry, not a loop: a second failure is a real error, not a race.
      it 'gives up after one retry' do
        allow(LtiCourseBinding).to receive(:find_or_initialize_by) do |**args|
          LtiCourseBinding.new(**args)
        end
        expect { lti_session.find_or_create_binding! }
          .to raise_error(ActiveRecord::RecordNotUnique)
      end
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

    # The roster sync creating this member's row while the student's own launch
    # creates it, or two tabs of one launch: both observe no row, and the
    # (user_lti_id, binding) unique index makes one save raise. The first lookup
    # is forced to return an unsaved record so the index fires for real.
    describe 'when a concurrent launch creates the context first' do
      let!(:binding) { lti_session.find_or_create_binding! }

      def force_stale_first_lookup
        calls = 0
        allow(LtiContext).to receive(:find_or_initialize_by).and_wrap_original do |orig, *args|
          calls += 1
          calls == 1 ? LtiContext.new(**args.first) : orig.call(*args)
        end
      end

      it 'adopts the winning row instead of raising' do
        winner = LtiContext.create!(user_lti_id: 'lti-user-1', lti_course_binding: binding,
                                    lms_id: 'platform-x')
        force_stale_first_lookup

        ctx = lti_session.link_lti_user(user)
        expect(ctx.id).to eq(winner.id)
        expect(ctx.user).to eq(user)
      end

      it 'creates no second context' do
        LtiContext.create!(user_lti_id: 'lti-user-1', lti_course_binding: binding,
                           lms_id: 'platform-x')
        force_stale_first_lookup

        expect { lti_session.link_lti_user(user) }.not_to change(LtiContext, :count)
      end

      # The retry re-runs the write-once check against the winner's row, so a
      # race that is actually a conflict still ends at the handled error rather
      # than a 500.
      it 'raises ConflictingLinkError when the winner linked a different user' do
        LtiContext.create!(user_lti_id: 'lti-user-1', lti_course_binding: binding,
                           lms_id: 'platform-x', user: create(:user, username: 'Other'),
                           linked_at: 1.day.ago)
        force_stale_first_lookup

        expect { lti_session.link_lti_user(user) }
          .to raise_error(LtiSession::DuplicateUserLinkError)
      end
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
