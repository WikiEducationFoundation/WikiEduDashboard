# frozen_string_literal: true

require 'rails_helper'

describe LtiLineItemSyncWorker do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'p', lms_family: 'canvas',
      lms_context_id: 'c', lms_resource_link_id: 'r'
    )
  end

  before { allow(Features).to receive(:canvas_integration?).and_return(true) }

  it 'invokes SyncLtiLineItems with the binding' do
    expect(SyncLtiLineItems).to receive(:new).with(binding)
    described_class.new.perform(binding.id)
  end

  it 'is a no-op for a missing binding' do
    expect(SyncLtiLineItems).not_to receive(:new)
    described_class.new.perform(0)
  end

  # A job queued (or mid-retry) before the integration was switched off must not
  # keep calling out to LTIAAS; the cron dispatchers gate too, but not these.
  it 'is a no-op when the canvas integration feature is disabled' do
    allow(Features).to receive(:canvas_integration?).and_return(false)
    expect(SyncLtiLineItems).not_to receive(:new)
    described_class.new.perform(binding.id)
  end
end
