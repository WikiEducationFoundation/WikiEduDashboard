require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe RecentActivityController do
  let(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '.refresh_report_urls' do
    let(:subject) { get :refresh_report_urls }
    it 'triggers an import of iThenticate urls' do
      expect(PlagiabotImporter).to receive(:import_report_urls)
      expect(subject).to redirect_to '/recent-activity/plagiarism'
    end
  end
end
