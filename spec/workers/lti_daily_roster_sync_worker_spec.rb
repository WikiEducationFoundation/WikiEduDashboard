# frozen_string_literal: true

require 'rails_helper'

describe LtiDailyRosterSyncWorker do
  let!(:in_window_course) do
    create(:course, slug: 'school/active_(term)', start: 30.days.ago, end: 30.days.from_now)
  end
  let!(:expired_course) do
    create(:course, slug: 'school/expired_(term)',
                    start: 200.days.ago, end: 90.days.ago)
  end

  before do
    LtiCourseBinding.create!(
      course: in_window_course, lms_id: 'p1', lms_family: 'canvas',
      lms_context_id: 'c1', lms_resource_link_id: 'r1',
      ltiaas_service_credentials: 'svc-1'
    )
    LtiCourseBinding.create!(
      course: expired_course, lms_id: 'p2', lms_family: 'canvas',
      lms_context_id: 'c2', lms_resource_link_id: 'r2',
      ltiaas_service_credentials: 'svc-2'
    )
    LtiCourseBinding.create!(
      course: in_window_course && create(:course, slug: 'no_creds/term'),
      lms_id: 'p3', lms_family: 'canvas',
      lms_context_id: 'c3', lms_resource_link_id: 'r3',
      ltiaas_service_credentials: nil
    )
  end

  it 'enqueues a sync only for active bindings with stored credentials' do
    enqueued_ids = []
    allow(LtiRosterSyncWorker).to receive(:perform_async) { |id| enqueued_ids << id }

    described_class.new.perform

    expect(enqueued_ids.size).to eq(1)
    expect(LtiCourseBinding.find(enqueued_ids.first).course).to eq(in_window_course)
  end
end
