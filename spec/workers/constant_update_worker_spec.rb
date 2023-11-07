# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app/workers/constant_update_worker')

describe ConstantUpdateWorker do
  let(:course) { create(:course) }

  it 'starts a ConstantUpdate' do
    expect(ConstantUpdate).to receive(:new)
    described_class.set(queue: 'constant_update').perform_async
  end
end
