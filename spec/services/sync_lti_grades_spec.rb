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

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
    allow(LtiLineItemSyncWorker).to receive(:perform_in)

    # Stub the upstream POST/PUT calls SyncLtiLineItems will make.
    stub_request(:post, "https://#{domain}/api/lineitems")
      .with(body: hash_including(label: 'Wikipedia trainings'))
      .to_return(status: 201,
                 body: { id: trainings_lineitem_url, label: 'Wikipedia trainings',
                         scoreMaximum: 1.0 }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, "https://#{domain}/api/lineitems")
      .with(body: hash_including(label: 'Wk1 Find sources'))
      .to_return(status: 201,
                 body: { id: exercise_lineitem_url, label: 'Wk1 Find sources',
                         scoreMaximum: 1.0 }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def stub_post_score(lineitem_url)
    stub_request(:post, "https://#{domain}/api/lineitems/" \
                        "#{CGI.escape(lineitem_url)}/scores")
      .to_return(status: 204, body: '', headers: {})
  end

  it 'pushes scores only for linked students' do
    trainings_stub = stub_post_score(trainings_lineitem_url)
    exercise_stub = stub_post_score(exercise_lineitem_url)

    described_class.new(binding)

    expect(trainings_stub).to have_been_requested.once
    expect(exercise_stub).to have_been_requested.once
    expect(WebMock).not_to have_requested(:post, /scores/)
      .with(body: hash_including(userId: 'lti-bob'))
  end

  it 'updates last_grade_sync_at' do
    stub_post_score(trainings_lineitem_url)
    stub_post_score(exercise_lineitem_url)

    described_class.new(binding)
    expect(binding.reload.last_grade_sync_at).to be_present
  end

  it 'pushes 1.0 + sandbox-URL comment when the exercise is marked complete' do
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
end
