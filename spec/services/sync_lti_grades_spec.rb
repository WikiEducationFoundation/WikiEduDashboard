# frozen_string_literal: true

require 'rails_helper'

describe SyncLtiGrades do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:course) do
    create(:course).tap { |c| c.campaigns << Campaign.first }
  end
  let(:binding) do
    LtiCourseBinding.create!(
      course: course,
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key',
      gradebook_granularity: 'lumped'
    )
  end

  let(:training_module) do
    create(:training_module, slug: 'tr-1', name: 'Training', kind: 0)
  end
  let(:exercise_module) do
    create(:training_module, slug: 'ex-1', name: 'Bibliography',
                             kind: 1, settings: { 'sandbox_location' => 'sandbox/Bib' })
  end
  let!(:week) { create(:week, course: course, order: 1) }
  let!(:training_block) do
    create(:block, week: week, order: 0, title: 'Get started',
                   training_module_ids: [training_module.id])
  end
  let!(:exercise_block) do
    create(:block, week: week, order: 1, title: 'Find sources',
                   training_module_ids: [exercise_module.id])
  end

  let(:student_user) { create(:user, username: 'Alice', email: 'alice@example.edu') }
  let!(:linked_context) do
    LtiContext.create!(
      lti_course_binding: binding, user: student_user, user_lti_id: 'lti-alice',
      lms_id: 'platform-x', linked_at: 1.day.ago
    )
  end
  let!(:unlinked_context) do
    LtiContext.create!(
      lti_course_binding: binding, user: nil, user_lti_id: 'lti-bob',
      lms_id: 'platform-x', email: 'bob@example.edu'
    )
  end

  let(:trainings_lineitem_url) { 'https://lms.example.com/li/trainings' }
  let(:exercise_lineitem_url) { 'https://lms.example.com/li/find-sources' }
  let(:setup_lineitem_url) { 'https://lms.example.com/li/setup' }

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
    allow(LtiLineItemSyncWorker).to receive(:perform_in)

    # Stub the upstream call SyncLtiLineItems makes first: in lumped
    # (deep-link-first) mode it creates nothing and DISCOVERS the
    # instructor-imported columns via GET, matching each by its resource-
    # marker tag. Return all three so their local rows bind and grade sync
    # can push to them.
    stub_request(:get, %r{https://#{domain}/api/lineitems})
      .to_return(status: 200,
                 body: { lineItems: [
                   { 'id' => setup_lineitem_url, 'tag' => LtiLineItem::SETUP_TYPE },
                   { 'id' => trainings_lineitem_url,
                     'tag' => LtiLineItem::TRAINING_PROGRESS_TYPE },
                   { 'id' => exercise_lineitem_url, 'tag' => "Block:#{exercise_block.id}" }
                 ] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    stub_post_score(setup_lineitem_url)
  end

  def stub_post_score(lineitem_url)
    stub_request(:post, "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(lineitem_url)}/scores")
      .to_return(status: 204, body: '', headers: {})
  end

  it 'never grades an instructor (Canvas rejects a non-student score with a 422)' do
    # A linked instructor context would otherwise get the setup 1.0 posted,
    # which Canvas rejects — the source of the Sentry flood.
    instructor = create(:user, username: 'Prof')
    LtiContext.create!(
      lti_course_binding: binding, user: instructor, user_lti_id: 'lti-prof',
      lms_id: 'platform-x', linked_at: 1.day.ago,
      roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor']
    )
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)

    expect(WebMock).not_to have_requested(:post, %r{/scores})
      .with(body: hash_including(userId: 'lti-prof'))
  end

  it 'does not report to Sentry when Canvas says the user is not a student (422)' do
    allow(Sentry).to receive(:capture_exception)
    # The connected student's setup post comes back a membership-gone 422.
    stub_request(:post, "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(setup_lineitem_url)}/scores")
      .to_return(status: 422,
                 body: { error: 'User not found in course or is not a student' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)

    expect(Sentry).not_to have_received(:capture_exception)
    expect(binding.reload.last_grade_sync_at).to be_present
  end

  it 'marks the connected student set up (1.0) and never seeds a failing 0 for others' do
    # Alice is linked and complete on the training + exercise, so those post 1.0.
    TrainingModulesUsers.create!(user: student_user, training_module:,
                                 completed_at: 1.day.ago)
    tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module)
    tmu.flags = { course.id => { marked_complete: true } }
    tmu.save!
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)

    # Setup: the connected student gets 1.0; the not-yet-connected student
    # (lti-bob) is NOT posted a 0 — Canvas can't exclude the column from the
    # total, so a 0 would read as failing. Left ungraded/blank instead.
    expect(WebMock).to have_requested(:post, %r{setup/scores})
      .with(body: hash_including(userId: 'lti-alice', scoreGiven: 1.0))
    expect(WebMock).not_to have_requested(:post, %r{setup/scores})
      .with(body: hash_including(userId: 'lti-bob'))
    # Training/exercise columns only ever grade the linked student.
    expect(WebMock).not_to have_requested(:post, %r{trainings/scores})
      .with(body: hash_including(userId: 'lti-bob'))
    expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
      .with(body: hash_including(userId: 'lti-bob'))
  end

  it 'leaves a linked student with no progress ungraded rather than posting 0' do
    # No completions for alice → training roll-up and exercise are both 0.
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)

    # A fresh 0 is never seeded (it would read as a failing 0% in the course
    # total); the column stays blank until there's real progress.
    expect(WebMock).not_to have_requested(:post, %r{trainings/scores})
      .with(body: hash_including(userId: 'lti-alice'))
    expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
      .with(body: hash_including(userId: 'lti-alice'))
  end

  it 'updates last_grade_sync_at' do
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)
    expect(binding.reload.last_grade_sync_at).to be_present
  end

  it 'pushes 1.0 without leaking the sandbox URL into the score comment' do
    tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module,
                                   completed_at: 1.day.ago)
    tmu.flags = { course.id => { marked_complete: true } }
    tmu.save!
    stub_post_score(trainings_lineitem_url)
    stub = stub_request(:post,
                        "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(exercise_lineitem_url)}/scores")
           .with(body: hash_including(scoreGiven: 1.0,
                                      userId: 'lti-alice'))
           .to_return(status: 204, body: '', headers: {})

    described_class.new(binding)
    expect(stub).to have_been_requested
    # The student's Wikipedia username must not cross into the Canvas gradebook
    # via the AGS comment (the sandbox URL embeds "User:<username>").
    expect(WebMock).not_to have_requested(:post, %r{/scores})
      .with { |req| req.body.to_s.include?('sandbox') }
  end

  it 'pushes 1.0 for a lumped-mode mixed block whose exercise is the only completion' do
    other_training = create(:training_module, slug: 'tr-2', name: 'Side training', kind: 0)
    mixed_block = create(:block, week: week, order: 2, title: 'Evaluate Wikipedia',
                                 training_module_ids: [other_training.id,
                                                       exercise_module.id])
    mixed_lineitem_url = 'https://lms.example.com/li/mixed'
    # Both exercise blocks are deep-link-created; discovery binds them by tag.
    stub_request(:get, %r{https://#{domain}/api/lineitems})
      .to_return(status: 200,
                 body: { lineItems: [
                   { 'id' => exercise_lineitem_url, 'tag' => "Block:#{exercise_block.id}" },
                   { 'id' => mixed_lineitem_url, 'tag' => "Block:#{mixed_block.id}" }
                 ] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module)
    tmu.flags = { course.id => { marked_complete: true } }
    tmu.save!
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)
    mixed_stub = stub_request(:post,
                              "https://#{domain}/api/lineitems/" \
                              "#{CGI.escape(mixed_lineitem_url)}/scores")
                 .with(body: hash_including(scoreGiven: 1.0, userId: 'lti-alice'))
                 .to_return(status: 204, body: '', headers: {})

    described_class.new(binding)
    expect(mixed_stub).to have_been_requested
    expect(mixed_block).to be_persisted # silence rubocop unused-var
  end

  it 'is a no-op when binding has no service credentials' do
    binding.update!(ltiaas_service_credentials: nil)
    described_class.new(binding)
    expect(WebMock).not_to have_requested(:post, /scores/)
  end

  it 'continues past per-record failures and reports them to Sentry' do
    expect(Sentry).to receive(:capture_exception).at_least(:once)
    stub_request(:post, /scores/).to_return(status: 500, body: 'boom')
    described_class.new(binding) # should not raise
    expect(binding.reload.last_grade_sync_at).to be_present
  end

  describe 'dedup via LtiScoreSignature' do
    # Give Alice real progress so every column posts a non-zero score — zeros
    # are no longer seeded, so an all-zero run would post (and dedup) nothing.
    def complete_alice
      TrainingModulesUsers.create!(user: student_user, training_module:,
                                   completed_at: 1.day.ago)
      tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
    end

    it 'skips the POST when the next signature matches a stored one' do
      complete_alice
      trainings_stub = stub_post_score(trainings_lineitem_url)
      exercise_stub = stub_post_score(exercise_lineitem_url)

      described_class.new(binding) # first call: signatures get written

      expect(trainings_stub).to have_been_requested.once
      expect(exercise_stub).to have_been_requested.once
      # 3 = Alice's trainings + exercise + setup. Bob's unlinked setup 0 is
      # not seeded, so no signature for it.
      expect(LtiScoreSignature.count).to eq(3)

      described_class.new(binding) # second call: state unchanged → no POSTs

      expect(trainings_stub).to have_been_requested.once
      expect(exercise_stub).to have_been_requested.once
    end

    it 'POSTs again when the score signature changes between cycles' do
      # Alice completes the one training → roll-up 1/1 = 1.0 (signature set).
      TrainingModulesUsers.create!(user: student_user, training_module:,
                                   completed_at: 1.day.ago)
      stub_post_score(trainings_lineitem_url)
      stub_post_score(exercise_lineitem_url)
      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{trainings/scores\z}).once

      # Add a second training (incomplete) → roll-up drops to 1/2 → changed.
      training = create(:training_module, slug: 'tr-2', name: 'Other', kind: 0)
      create(:block, week: week, order: 5, title: 'Wk1 trainings',
                     training_module_ids: [training.id])

      # Force a fresh AR fetch of binding.course.blocks (in production each
      # worker run loads its own binding; in this test we reuse the let).
      binding.reload
      described_class.new(binding)

      # Trainings line item POSTed again (signature changed: 1/2 now).
      expect(WebMock).to have_requested(:post, %r{trainings/scores\z}).twice
    end

    it 'records a signature row keyed to (line item, context) after a successful POST' do
      complete_alice
      stub_post_score(trainings_lineitem_url)
      stub_post_score(exercise_lineitem_url)
      described_class.new(binding)
      sigs = LtiScoreSignature.where(lti_context_id: linked_context.id)
      expect(sigs.count).to eq(3) # trainings + exercise + setup
      expect(sigs.map(&:signature).uniq.size).to eq(3) # one per line item
      expect(sigs.first.last_pushed_at).to be_within(5.seconds).of(Time.current)
    end

    it 'does not record a signature when the POST fails' do
      complete_alice
      allow(Sentry).to receive(:capture_exception)
      stub_request(:post, /scores/).to_return(status: 500, body: 'boom')
      described_class.new(binding)
      expect(LtiScoreSignature.count).to eq(0)
    end
  end
end
