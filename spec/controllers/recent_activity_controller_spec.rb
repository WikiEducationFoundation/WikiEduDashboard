# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/plagiabot_importer"

describe RecentActivityController do
  let(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '.plagiarism_report' do
    let(:subject) { get :plagiarism_report, params: { ithenticate_id: 123 } }
    it 'fetches an iThenticate url and redirects' do
      expect(PlagiabotImporter).to receive(:api_get_url)
        .with(ithenticate_id: '123').and_return(root_path)
      expect(subject).to redirect_to root_path
    end
  end
end
