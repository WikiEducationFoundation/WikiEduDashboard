# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/app/workers/score_detector_comparison_core_worker"

describe ScoreDetectorComparisonCoreWorker do
  it 'queues the next chunk while the run has work left' do
    allow(ScoreDetectorComparisonCore).to receive(:step).with('run1').and_return(true)
    allow(described_class).to receive(:perform_async)

    described_class.new.perform('run1')

    expect(described_class).to have_received(:perform_async).with('run1')
  end

  it 'stops queuing when the run is finished or stopped' do
    allow(ScoreDetectorComparisonCore).to receive(:step).with('run1').and_return(false)
    allow(described_class).to receive(:perform_async)

    described_class.new.perform('run1')

    expect(described_class).not_to have_received(:perform_async)
  end
end
