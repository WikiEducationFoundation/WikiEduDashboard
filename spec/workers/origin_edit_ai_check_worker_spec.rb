# frozen_string_literal: true

require 'rails_helper'

describe OriginEditAiCheckWorker do
  let(:attributes) { { 'mw_rev_id' => 123, 'passages' => ['Old text.'] } }

  it 'checks the origin edits' do
    expect(CheckOriginEditsWithPangram).to receive(:new).with(attributes)
    described_class.new.perform(attributes)
  end

  it 'falls back to the regular alert once retries run out' do
    expect(CheckOriginEditsWithPangram).to receive(:new).with(attributes, check_origins: false)
    described_class.sidekiq_retries_exhausted_block.call({ 'args' => [attributes] },
                                                         StandardError.new)
  end
end
