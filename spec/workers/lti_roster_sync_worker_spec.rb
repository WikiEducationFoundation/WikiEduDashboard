# frozen_string_literal: true

require 'rails_helper'

describe LtiRosterSyncWorker do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end

  it 'invokes SyncLtiRoster with the binding' do
    expect(SyncLtiRoster).to receive(:new).with(binding)
    described_class.new.perform(binding.id)
  end

  it 'is a no-op for a missing binding (e.g. deleted between enqueue and run)' do
    expect(SyncLtiRoster).not_to receive(:new)
    described_class.new.perform(0)
  end

  describe '.schedule' do
    it 'enqueues the worker by binding id' do
      expect(described_class).to receive(:perform_async).with(binding.id)
      described_class.schedule(binding.id)
    end
  end
end
