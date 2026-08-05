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
      ltiaas_service_credentials: 'svc-key'
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
  # Roles are load-bearing, not decoration: only LEARNER_ROLES memberships are
  # graded, so a context with no roles claim is not a student. Every real
  # context gets its roles from the launch or from NRPS.
  let(:learner_roles) { ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'] }
  let!(:linked_context) do
    LtiContext.create!(
      lti_course_binding: binding, user: student_user, user_lti_id: 'lti-alice',
      lms_id: 'platform-x', roles: learner_roles, linked_at: 1.day.ago
    )
  end
  let!(:unlinked_context) do
    LtiContext.create!(
      lti_course_binding: binding, user: nil, user_lti_id: 'lti-bob',
      lms_id: 'platform-x', roles: learner_roles
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

  def submission_claim(request)
    JSON.parse(request.body)['https://canvas.instructure.com/lti/submission'] || {}
  end

  # Exercise work is the instructor's to evaluate; the Dashboard only knows the
  # student marked it done. Reporting that as 1/1 asserted a judgment nobody had
  # made. Submitted + PendingManual with no score is how AGS says "submitted,
  # please grade" — Canvas creates the submission and leaves it ungraded.
  describe 'an instructor-graded exercise column' do
    before do
      tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module)
      tmu.flags = { course.id => { marked_complete: true } }
      tmu.save!
      stub_post_score(trainings_lineitem_url)
      stub_post_score(setup_lineitem_url)
      stub_post_score(exercise_lineitem_url)
    end

    it 'reports submission for grading instead of a score' do
      described_class.new(binding)

      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| !JSON.parse(req.body).key?('scoreGiven') }
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with(body: hash_including(activityProgress: 'Submitted',
                                   gradingProgress: 'PendingManual'))
    end

    # scoreMaximum without scoreGiven would assert a denominator for a grade
    # that isn't being reported.
    it 'omits scoreMaximum along with the score' do
      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| !JSON.parse(req.body).key?('scoreMaximum') }
    end

    # Without a submission behind the score, Canvas answers an instructor who
    # opens the student's work with "No Preview Available". The extension hands it
    # a launch URL to render instead.
    it 'carries a submission launch URL for the instructor to open' do
      described_class.new(binding)

      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req)['submission_type'] == 'basic_lti_launch' }
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req)['submission_data'].include?('submission=lti-alice') }
    end

    # The URL names the student, because the view it opens is about one student and
    # a submission view that can't say whose work it is tells the instructor nothing.
    # By LMS user id: this URL is persisted inside Canvas, where a Wikipedia
    # username must not go — the same rule that keeps sandbox URLs out of score
    # comments — and Canvas already knows its own id for the student.
    it 'identifies the column and the student, never the Wikipedia username' do
      described_class.new(binding)

      marker = "Block%3A#{exercise_block.id}"
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req)['submission_data'].include?(marker) }
      expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req).to_s.include?('Alice') }
    end

    # Canvas stores the submission URL only when the score claims a new submission
    # (verified on staging: with false, the submission existed with a nil url and
    # the instructor still got "No Preview Available").
    it 'claims a new submission on the first push, so Canvas keeps the URL' do
      described_class.new(binding)

      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req)['new_submission'] == true }
    end

    # And only on the first: a new submission is a new attempt, so repeating it
    # would pile up history and push an already-graded submission back into the
    # needs-grading queue. The URL persists on the attempt it arrived with.
    it 'sends no submission claim on a later push for the same student' do
      described_class.new(binding)
      line_item = LtiLineItem.find_by(lineitem_id: exercise_lineitem_url)
      # A changed signature is what lets a second push through the dedup.
      LtiScoreSignature.where(lti_line_item_id: line_item.id).update_all(signature: 'stale')
      WebMock.reset_executed_requests!

      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
      expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req).any? }
    end

    # Every course already running when this shipped has a signature for each pair
    # and no submission behind it. Keying the extension on "nothing pushed yet" left
    # those permanently on Canvas's "No Preview Available" — the marker is persisted
    # so an unchanged score still gets one push to carry the URL.
    it 'sends the submission claim for a pair that has never had one' do
      described_class.new(binding)
      LtiScoreSignature.update_all(submission_reported_at: nil)
      WebMock.reset_executed_requests!

      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{find-sources/scores})
        .with { |req| submission_claim(req)['submission_type'] == 'basic_lti_launch' }
    end

    # ...and having sent it, stops: the marker is what makes it one push and not one
    # per sync cycle, forever.
    it 'stops sending it once the marker records that Canvas has one' do
      described_class.new(binding)
      LtiScoreSignature.update_all(submission_reported_at: nil)
      described_class.new(binding)
      WebMock.reset_executed_requests!

      described_class.new(binding)
      expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
    end

    # The mechanical columns are unaffected: there, completion IS the grade.
    it 'still posts a real score for the setup indicator' do
      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{setup/scores})
        .with(body: hash_including(scoreGiven: 1.0, gradingProgress: 'FullyGraded'))
    end

    # An instructor who opens ANY column in SpeedGrader would otherwise meet
    # Canvas's bare "No Preview Available" — including the mechanical ones, which
    # is what the operator hit on the "Wikipedia account" column. Every column
    # gets a launchable submission on its first push.
    it 'carries a submission launch URL on the mechanical columns too' do
      described_class.new(binding)

      expect(WebMock).to have_requested(:post, %r{setup/scores})
        .with { |req| submission_claim(req)['submission_type'] == 'basic_lti_launch' }
      expect(WebMock).to have_requested(:post, %r{setup/scores})
        .with { |req| submission_claim(req)['submission_data'].include?('WikipediaSetup') }
    end

    it 'still sends no submission claim on a later push for a mechanical column' do
      described_class.new(binding)
      line_item = LtiLineItem.find_by(lineitem_id: setup_lineitem_url)
      LtiScoreSignature.where(lti_line_item_id: line_item.id).update_all(signature: 'stale')
      WebMock.reset_executed_requests!

      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{setup/scores})
      expect(WebMock).not_to have_requested(:post, %r{setup/scores})
        .with { |req| submission_claim(req).any? }
    end
  end

  describe 'an exercise the student has not finished' do
    before do
      stub_post_score(trainings_lineitem_url)
      stub_post_score(setup_lineitem_url)
      stub_post_score(exercise_lineitem_url)
    end

    it 'reports nothing at all' do
      described_class.new(binding)
      expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
    end

    # Un-marking finished work can't be retracted through AGS, and overwriting
    # the instructor's grade isn't ours to do — so an unfinished exercise stays
    # silent even where a mechanical column would post a correcting zero.
    it 'does not post a zero even once something has been reported before' do
      described_class.new(binding) # binds the line items via discovery
      line_item = LtiLineItem.find_by(lineitem_id: exercise_lineitem_url)
      LtiScoreSignature.create!(lti_line_item: line_item, lti_context: linked_context,
                                signature: 'stale', last_pushed_at: 1.day.ago)
      WebMock.reset_executed_requests!

      described_class.new(binding)
      expect(WebMock).not_to have_requested(:post, %r{find-sources/scores})
    end
  end

  # activityProgress travels with the score and Canvas may act on it: an
  # activity reported Completed is finished work. The trainings roll-up pushes
  # fractions, so a blanket Completed contradicted the score beside it.
  describe 'the activity progress reported alongside a score' do
    let!(:second_training) do
      other = create(:training_module, slug: 'tr-2', name: 'Second training', kind: 0)
      create(:block, week: week, order: 3, title: 'More training',
                     training_module_ids: [other.id])
    end

    before do
      stub_post_score(exercise_lineitem_url)
      stub_post_score(setup_lineitem_url)
      stub_post_score(trainings_lineitem_url)
      # One of the two trainings done: the roll-up posts 0.5.
      TrainingModulesUsers.create!(user: student_user, training_module:,
                                   completed_at: 1.day.ago)
    end

    it 'reports partial training progress as InProgress' do
      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{trainings/scores})
        .with(body: hash_including(scoreGiven: 0.5, activityProgress: 'InProgress',
                                   gradingProgress: 'FullyGraded'))
      expect(second_training).to be_persisted
    end

    it 'still reports a full score as Completed' do
      described_class.new(binding)
      expect(WebMock).to have_requested(:post, %r{setup/scores})
        .with(body: hash_including(scoreGiven: 1.0, activityProgress: 'Completed'))
    end
  end

  it 'appends the Dashboard origin to a posted score comment' do
    # Alice is connected, so the setup column posts "✓"; the appended origin
    # makes Canvas's authorless "- Someone" attribution legible.
    stub_post_score(setup_lineitem_url)
    described_class.new(binding)
    expect(WebMock).to have_requested(:post, %r{setup/scores})
      .with { |req| req.body.include?('✓ — dashboard.wikiedu.org') }
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

  # The exercise column reports submission for grading rather than a score (see
  # the instructor-graded describe below); what this example guards is the
  # privacy rule that holds either way.
  it 'reports a finished exercise without leaking the sandbox URL into the comment' do
    tmu = TrainingModulesUsers.new(user: student_user, training_module: exercise_module,
                                   completed_at: 1.day.ago)
    tmu.flags = { course.id => { marked_complete: true } }
    tmu.save!
    stub_post_score(trainings_lineitem_url)
    stub = stub_request(:post,
                        "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(exercise_lineitem_url)}/scores")
           .with(body: hash_including(userId: 'lti-alice',
                                      gradingProgress: 'PendingManual'))
           .to_return(status: 204, body: '', headers: {})

    described_class.new(binding)
    expect(stub).to have_been_requested
    # The student's Wikipedia username must not cross into the Canvas gradebook
    # via the AGS comment (the sandbox URL embeds "User:<username>").
    expect(WebMock).not_to have_requested(:post, %r{/scores})
      .with { |req| req.body.to_s.include?('sandbox') }
  end

  # The point here is which modules count: a mixed block's exercise completion is
  # enough on its own, and the surrounding trainings (graded by the roll-up
  # column) must not zero it out.
  it 'reports a mixed block whose exercise is the only completion' do
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
                 .with(body: hash_including(userId: 'lti-alice',
                                            activityProgress: 'Submitted'))
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

  # A 422 that isn't the membership-gone case is a permanent rejection of one
  # student's score: skip it, report it, keep going.
  def stub_rejected_score(lineitem_url)
    stub_request(:post, "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(lineitem_url)}/scores")
      .to_return(status: 422, body: { error: 'scoreGiven is invalid' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'continues past per-record failures and reports them to Sentry' do
    expect(Sentry).to receive(:capture_exception).at_least(:once)
    stub_rejected_score(setup_lineitem_url)
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)
    described_class.new(binding) # should not raise
    expect(binding.reload.last_grade_sync_at).to be_present
  end

  it 'records a partial-success run in last_grade_sync_error' do
    allow(Sentry).to receive(:capture_exception)
    stub_rejected_score(setup_lineitem_url)
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)
    described_class.new(binding)
    expect(binding.reload.last_grade_sync_error).to include('score push(es) failed')
  end

  it 'clears a stale last_grade_sync_error after a clean run' do
    binding.update!(last_grade_sync_error: 'AGS POST failed: 401')
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)
    described_class.new(binding)
    expect(binding.reload.last_grade_sync_error).to be_nil
  end

  # A fresh deep-link reservation has no lineitem_id — there is nothing to post
  # at, and letting it into the push loop would raise a TypeError that (as a
  # non-API error) aborts the whole run.
  it 'skips pending deep-link reservations rather than posting at a nil line item' do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                        gradable_id: training_block.id, label: 'Get started')
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)
    described_class.new(binding)
    expect(binding.reload.last_grade_sync_error).to be_nil
    expect(binding.last_grade_sync_at).to be_present
  end

  # A bug in progress computation (or any other non-API failure) is systemic,
  # not a per-student rejection: it must abort the run and reach Sidekiq's
  # retry rather than recording a completed partial sync.
  describe 'internal application errors' do
    before do
      binding.update!(last_grade_sync_at: 3.hours.ago)
      allow(Sentry).to receive(:capture_exception)
    end

    it 'aborts the run instead of recording per-student failures' do
      allow(LtiSetupProgress).to receive(:new).and_raise(RuntimeError, 'progress bug')
      expect { described_class.new(binding) }.to raise_error(RuntimeError, 'progress bug')
      expect(binding.reload.last_grade_sync_at).to be_within(5.seconds).of(3.hours.ago)
      expect(binding.last_grade_sync_error).to include('RuntimeError')
    end
  end

  # A 5xx, a rate limit, or an auth failure hits every push in the run, so
  # reporting a fresh successful sync would be actively misleading. Let it out
  # so Sidekiq retries.
  describe 'whole-run LTIAAS failures' do
    before do
      binding.update!(last_grade_sync_at: 3.hours.ago)
      allow(Sentry).to receive(:capture_exception)
    end

    it 'raises rather than reporting success when LTIAAS returns a 500' do
      stub_request(:post, /scores/).to_return(status: 500, body: 'boom')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasTransientError)
    end

    it 'leaves last_grade_sync_at untouched and records the error on a 500' do
      stub_request(:post, /scores/).to_return(status: 500, body: 'boom')
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(binding.reload.last_grade_sync_at).to be_within(5.seconds).of(3.hours.ago)
      expect(binding.last_grade_sync_error).to include('LtiaasTransientError')
    end

    it 'raises on a rate limit so the retry backs off' do
      stub_request(:post, /scores/).to_return(status: 429, body: 'slow down')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasRateLimitError)
      expect(binding.reload.last_grade_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end

    it 'raises on an auth failure so a stale service key surfaces' do
      stub_request(:post, /scores/).to_return(status: 401, body: 'nope')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasAuthError)
      expect(binding.reload.last_grade_sync_error).to include('LtiaasAuthError')
    end

    # The line-item sync runs first and can fail on its own. A 404 from it is a
    # plain LtiaasClientError, outside the per-score aborting tier, and used to
    # escape with neither field written — so the job dead-lettered while the
    # status views reported a healthy binding.
    it 'records a failure from the line-item sync that runs first' do
      stub_request(:get, %r{https://#{domain}/api/lineitems})
        .to_return(status: 404, body: 'no such context')
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasClientError)
      expect(binding.reload.last_grade_sync_error).to include('LtiaasClientError')
      expect(binding.last_grade_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end

    # TLS and body-parsing failures are siblings of ConnectionFailed under
    # Faraday::Error, so they used to slip past the client's transient mapping.
    it 'treats a TLS failure as a whole-run transient failure' do
      stub_request(:post, /scores/).to_raise(Faraday::SSLError.new('handshake failed'))
      expect { described_class.new(binding) }
        .to raise_error(LtiaasClient::LtiaasTransientError)
      expect(binding.reload.last_grade_sync_at).to be_within(5.seconds).of(3.hours.ago)
    end
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
      expect { described_class.new(binding) }.to raise_error(StandardError)
      expect(LtiScoreSignature.count).to eq(0)
    end
  end
end
