# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/importers/plagiabot_importer')

describe RecentActivityController, type: :request do
  let(:user) { create(:user) }

  describe '.plagiarism_report' do
    context 'when the user is logged in' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      let(:subject) { get '/recent-activity/plagiarism/report', params: { ithenticate_id: 123 } }

      it 'fetches an iThenticate url and redirects' do
        expect(PlagiabotImporter).to receive(:api_get_url)
          .with(ithenticate_id: '123').and_return(root_path)
        expect(subject).to redirect_to root_path
      end
    end

    context 'when the user is logged out' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      let(:subject) { get '/recent-activity/plagiarism/report', params: { ithenticate_id: 123 } }

      it 'redirects to login' do
        expect(subject).to redirect_to %r{/users/auth/mediawiki}
      end
    end
  end
end
