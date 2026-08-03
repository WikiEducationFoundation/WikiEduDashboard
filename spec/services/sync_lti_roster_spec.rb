# frozen_string_literal: true

require 'rails_helper'

describe SyncLtiRoster do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:course) do
    create(:course).tap { |c| c.campaigns << Campaign.first }
  end
  let(:binding) do
    LtiCourseBinding.create!(
      course: course,
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key'
    )
  end
  let(:memberships_url) { "https://#{domain}/api/memberships" }

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  def stub_memberships(body)
    stub_request(:get, memberships_url)
      .to_return(status: 200, body: body.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'creates an LtiContext for each member and updates last_roster_sync_at' do
    stub_memberships(
      'members' => [
        { 'userId' => 'lti-1', 'name' => 'Alice', 'email' => 'alice@example.edu',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Active' },
        { 'userId' => 'lti-2', 'name' => 'Bob', 'email' => 'bob@example.edu',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'],
          'status' => 'Active' }
      ]
    )

    expect { described_class.new(binding) }
      .to change(LtiContext, :count).by(2)
    expect(binding.reload.last_roster_sync_at).to be_present
  end

  it 'is a no-op when the binding has no stored serviceKey' do
    binding.update!(ltiaas_service_credentials: nil)
    expect { described_class.new(binding) }
      .not_to change(LtiContext, :count)
    expect(binding.reload.last_roster_sync_at).to be_nil
    expect(WebMock).not_to have_requested(:get, memberships_url)
  end

  # Real vocabulary URIs, not a '#Learner' shorthand: role classification is an
  # allowlist match against the full LTI 1.3 strings, so an abbreviated fixture
  # would exercise the unsupported-role path instead of the learner one.
  def two_learners
    stub_memberships(
      'members' => [
        { 'userId' => 'lti-good',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Active' },
        { 'userId' => 'lti-bad',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Active' }
      ]
    )
  end

  def fail_one_member(error)
    allow(LtiMemberLinker).to receive(:new).and_call_original
    allow(LtiMemberLinker).to receive(:new)
      .with(anything, hash_including(user_lti_id: 'lti-bad'))
      .and_raise(error)
  end

  it 'continues past per-member errors and reports them to Sentry' do
    two_learners
    fail_one_member(KeyError.new('missing key'))
    expect(Sentry).to receive(:capture_exception)

    described_class.new(binding)
    expect(LtiContext.where(user_lti_id: 'lti-good')).to exist
  end

  it 'still advances last_roster_sync_at when one member is skipped' do
    two_learners
    fail_one_member(KeyError.new('missing key'))
    allow(Sentry).to receive(:capture_exception)

    described_class.new(binding)
    expect(binding.reload.last_roster_sync_at).to be_present
  end

  # A skipped member is still a student missing from the course, so the run
  # records the counts rather than reading as clean — `roster_sync_error?` is
  # what puts the "check the roster" notice on the status surfaces.
  it 'records the counts when a member is skipped' do
    two_learners
    fail_one_member(KeyError.new('missing key'))
    allow(Sentry).to receive(:capture_exception)

    described_class.new(binding)
    expect(binding.reload.last_roster_sync_error).to eq(
      '1 of 2 memberships failed; last: KeyError: missing key'
    )
  end

  it 'stores the NRPS membership status on each member context' do
    stub_memberships(
      'members' => [
        { 'userId' => 'lti-1',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Active' },
        { 'userId' => 'lti-2',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Inactive' }
      ]
    )

    described_class.new(binding)
    expect(LtiContext.find_by(user_lti_id: 'lti-1').lms_membership_status).to eq('Active')
    expect(LtiContext.find_by(user_lti_id: 'lti-2').lms_membership_status).to eq('Inactive')
  end

  # The defect this replaced: every per-member StandardError was swallowed and
  # then last_roster_sync_at advanced, so a sync in which every member failed —
  # or one that failed for a reason that had nothing to do with member data —
  # reported a fresh successful sync.
  describe 'failures that are not one member\'s problem' do
    before { binding.update!(last_roster_sync_at: 3.hours.ago) }

    it 'propagates an unexpected error instead of skipping the member' do
      two_learners
      fail_one_member(StandardError.new('boom'))
      expect { described_class.new(binding) }.to raise_error(StandardError, 'boom')
    end

    it 'does not report a successful sync when it aborts' do
      two_learners
      fail_one_member(StandardError.new('boom'))
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(binding.reload.last_roster_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end

    it 'propagates an LTIAAS 5xx on the membership fetch' do
      stub_request(:get, memberships_url).to_return(status: 500, body: 'boom')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasTransientError)
      expect(binding.reload.last_roster_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end

    it 'propagates an LTIAAS auth failure rather than skipping the roster' do
      two_learners
      fail_one_member(LtiaasClient::LtiaasAuthError.new('nope', 401))
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasAuthError)
    end

    # A dead-lettering roster sync used to be invisible on both status
    # surfaces: no error field, and last_roster_sync_at simply stopped
    # advancing. Same recording shape as SyncLtiGrades.
    it 'records last_roster_sync_error when the run aborts' do
      two_learners
      fail_one_member(StandardError.new('boom'))
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(binding.reload.last_roster_sync_error).to eq('StandardError: boom')
    end

    it 'records the error when the membership fetch itself fails' do
      stub_request(:get, memberships_url).to_return(status: 500, body: 'boom')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasTransientError)
      expect(binding.reload.last_roster_sync_error)
        .to include('LtiaasTransientError')
    end

    it 'clears the recorded error on the next successful run' do
      binding.update!(last_roster_sync_error: 'LtiaasClient::LtiaasTransientError: boom')
      two_learners
      described_class.new(binding)
      expect(binding.reload.last_roster_sync_error).to be_nil
    end
  end

  # A per-member error class that hits every member is not a roster of bad
  # memberships; it's one systemic failure (a linker bug, an NRPS shape change)
  # repeated per row. Skipping all of them and stamping a fresh timestamp showed
  # the instructor a successful sync with none of their students in it.
  describe 'when every member fails on a per-member error' do
    before do
      binding.update!(last_roster_sync_at: 3.hours.ago)
      two_learners
      allow(Sentry).to receive(:capture_exception)
      allow(LtiMemberLinker).to receive(:new).and_raise(KeyError.new('missing key'))
    end

    it 'aborts the run so Sidekiq retries it' do
      expect { described_class.new(binding) }
        .to raise_error(described_class::TotalMemberFailureError, /all 2 memberships failed/)
    end

    it 'does not advance last_roster_sync_at' do
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(binding.reload.last_roster_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end

    it 'records the failure' do
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(binding.reload.last_roster_sync_error)
        .to include('TotalMemberFailureError', 'all 2 memberships failed')
    end
  end

  # An empty roster is a legitimate state (a course with no enrollments yet), not
  # a total failure — it must not be mistaken for one and retried forever.
  it 'records a successful sync for an empty roster' do
    stub_memberships('members' => [])

    described_class.new(binding)
    expect(binding.reload.last_roster_sync_at).to be_present
    expect(binding.last_roster_sync_error).to be_nil
  end

  # Canvas can't reach a suspended or removed member either, so nothing should
  # join a Dashboard course on their behalf.
  describe 'members Canvas has suspended or removed' do
    %w[Inactive Deleted].each do |status|
      it "records but does not enroll a #{status} member" do
        stub_memberships(
          'members' => [
            { 'userId' => 'lti-1',
              'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
              'status' => status }
          ]
        )
        user = create(:user, username: 'Gone')
        LtiContext.create!(user:, lti_course_binding: binding, user_lti_id: 'lti-1',
                           lms_id: 'platform-x', linked_at: 1.day.ago)

        expect { described_class.new(binding) }.not_to change(CoursesUsers, :count)
        expect(LtiContext.find_by(user_lti_id: 'lti-1').roles).to include(/Learner/)
      end
    end
  end
end
