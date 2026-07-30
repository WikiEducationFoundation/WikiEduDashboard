# frozen_string_literal: true

require 'rails_helper'

describe LtiPeriodicGradeSyncWorker do
  let!(:active_course) do
    create(:course, slug: 'school/active_(term)', start: 30.days.ago, end: 30.days.from_now)
  end
  let!(:expired_course) do
    create(:course, slug: 'school/expired_(term)',
                    start: 200.days.ago, end: 60.days.ago)
  end
  let!(:no_creds_course) { create(:course, slug: 'school/no_creds_(term)') }

  before do
    allow(Features).to receive(:canvas_integration?).and_return(true)
    LtiCourseBinding.create!(
      course: active_course, lms_id: 'p1', lms_family: 'canvas',
      lms_context_id: 'c1', lms_resource_link_id: 'r1',
      ltiaas_service_credentials: 'svc-1'
    )
    LtiCourseBinding.create!(
      course: expired_course, lms_id: 'p2', lms_family: 'canvas',
      lms_context_id: 'c2', lms_resource_link_id: 'r2',
      ltiaas_service_credentials: 'svc-2'
    )
    LtiCourseBinding.create!(
      course: no_creds_course, lms_id: 'p3', lms_family: 'canvas',
      lms_context_id: 'c3', lms_resource_link_id: 'r3',
      ltiaas_service_credentials: nil
    )
  end

  it 'enqueues only active bindings with credentials' do
    enqueued = []
    allow(LtiGradeSyncWorker).to receive(:perform_async) { |id| enqueued << id }

    described_class.new.perform

    expect(enqueued.size).to eq(1)
    expect(LtiCourseBinding.find(enqueued.first).course).to eq(active_course)
  end

  it 'caps enqueues per cycle at PER_CYCLE_LIMIT' do
    stub_const('LtiPeriodicGradeSyncWorker::PER_CYCLE_LIMIT', 0)
    expect(LtiGradeSyncWorker).not_to receive(:perform_async)
    described_class.new.perform
  end

  # Dispatch orders on the *attempt* stamp, not the completion timestamp:
  # `last_grade_sync_at` only advances on a completed sync, so ordering on it
  # let a binding that always fails in the aborting tier keep its stale
  # timestamp and sort first every cycle, starving healthy bindings under the
  # per-cycle cap.
  describe 'dispatch ordering' do
    # The outer active binding has no attempt stamp, so it doubles as the
    # never-attempted binding here.
    let(:never_attempted) { LtiCourseBinding.find_by(course: active_course) }
    let!(:failing_binding) do
      course = create(:course, slug: 'school/failing_(term)',
                               start: 30.days.ago, end: 30.days.from_now)
      LtiCourseBinding.create!(
        course:, lms_id: 'p4', lms_family: 'canvas',
        lms_context_id: 'c4', lms_resource_link_id: 'r4',
        ltiaas_service_credentials: 'svc-4',
        last_grade_sync_at: nil, last_grade_sync_attempt_at: 10.minutes.ago
      )
    end
    let!(:healthy_binding) do
      course = create(:course, slug: 'school/healthy_(term)',
                               start: 30.days.ago, end: 30.days.from_now)
      LtiCourseBinding.create!(
        course:, lms_id: 'p5', lms_family: 'canvas',
        lms_context_id: 'c5', lms_resource_link_id: 'r5',
        ltiaas_service_credentials: 'svc-5',
        last_grade_sync_at: 1.hour.ago, last_grade_sync_attempt_at: 2.hours.ago
      )
    end

    def enqueued_ids
      ids = []
      allow(LtiGradeSyncWorker).to receive(:perform_async) { |id| ids << id }
      described_class.new.perform
      ids
    end

    it 'dispatches a never-attempted binding before everything else' do
      expect(enqueued_ids.first).to eq(never_attempted.id)
    end

    it 'dispatches least-recently-attempted bindings before recently-attempted ones' do
      ids = enqueued_ids
      expect(ids.index(healthy_binding.id)).to be < ids.index(failing_binding.id)
    end

    # The starvation case: the failing binding's stale completion timestamp no
    # longer wins it a slot every cycle once the cap fills with others.
    it 'leaves a recently-attempted failing binding out when the cap fills' do
      stub_const('LtiPeriodicGradeSyncWorker::PER_CYCLE_LIMIT', 2)
      expect(enqueued_ids).to contain_exactly(never_attempted.id, healthy_binding.id)
    end

    it 'stamps last_grade_sync_attempt_at on every binding it enqueues' do
      enqueued_ids
      expect(healthy_binding.reload.last_grade_sync_attempt_at)
        .to be_within(5.seconds).of(Time.current)
    end
  end
end
