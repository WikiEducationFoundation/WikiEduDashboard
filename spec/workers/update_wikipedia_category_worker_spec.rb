# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/update_wikipedia_category_worker"

describe UpdateWikipediaCategoryWorker do
  it 'starts a WikipediaCategoryMember service' do
    expect_any_instance_of(WikipediaCategoryMember).to receive(:fetch_category_members)
    described_class.new.perform
  end
end
