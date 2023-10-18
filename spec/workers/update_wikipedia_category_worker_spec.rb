# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe UpdateWikipediaCategoryWorker, type: :worker do
  it 'fetches and saves Wikipedia category members' do
    allow_any_instance_of(WikipediaCategoryMember).to receive(:fetch_category_members)

    expect do
      described_class.perform_async
    end.to change(described_class.jobs, :size).by(1)

    described_class.drain
  end
end
