# frozen_string_literal: true

require 'rails_helper'

describe LtiGradeSyncWorker do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'p', lms_family: 'canvas',
      lms_context_id: 'c', lms_resource_link_id: 'r'
    )
  end

  it 'invokes SyncLtiGrades with the binding' do
    expect(SyncLtiGrades).to receive(:new).with(binding)
    described_class.new.perform(binding.id)
  end

  it 'is a no-op for a missing binding' do
    expect(SyncLtiGrades).not_to receive(:new)
    described_class.new.perform(0)
  end
end
