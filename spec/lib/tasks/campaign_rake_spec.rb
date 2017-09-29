# frozen_string_literal: true

require 'rails_helper'

describe 'campaign:add_campaigns' do
  include_context 'rake'

  it 'calls Campaign.initialize_campaigns' do
    expect(Campaign).to receive(:initialize_campaigns)
    subject.invoke
  end
end
