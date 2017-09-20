# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/ores_scores_before_and_after_importer"

describe OresScoresBeforeAndAfterImporter do
  let(:course) { create(:course) }
  let(:article) { create(:article) }
  before do
    course.campaigns << Campaign.first
    course.articles << article
  end

  it 'runs without error' do
    described_class.new(campaign: Campaign.first)
  end
end
