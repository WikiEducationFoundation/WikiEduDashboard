# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateCourseStats do
  let(:course) { create(:course) } 
  let!(:article1) { create(:article) }
  let!(:article2) { create(:article) }
  let(:update_service) { described_class.new(course) }

  before do
    course.articles << [article1, article2]
  end

  describe '#update_average_pageviews' do
    it 'updates outdated average views for the course articles' do
      expect(AverageViewsImporter).to receive(:update_outdated_average_views)
        .with(course.articles, update_service: update_service)

      # Call the update_average_pageviews method directly
      update_service.send(:update_average_pageviews)
    end

    it 'logs the progress of average pageviews updates' do
      # Set up a spy on log_update_progress
      expect(update_service).to receive(:log_update_progress).with(:average_pageviews_updated)

      update_service.send(:update_average_pageviews)
    end
  end
end
