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
end
