# frozen_string_literal: true

require 'rails_helper'

describe LtiConfigController, type: :request do
  before do
    ENV['dashboard_url'] = 'dashboard.wikiedu.org'
    allow(Features).to receive_messages(canvas_integration?: true, lti_legacy_launches?: true)
  end

  describe 'GET /lti/legacy/config.xml' do
    it 'serves the LTI 1.1 cartridge pointing at our own legacy launch URL' do
      get '/lti/legacy/config.xml'
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/xml')
      expect(response.body).to include('<cartridge_basiclti_link')
      expect(response.body)
        .to include('<blti:launch_url>https://dashboard.wikiedu.org/lti/legacy/launch</blti:launch_url>')
    end

    # The anonymous posture and the one placement a 1.1 install gets: Canvas
    # reads both from the XML, since its manual-entry dialog offers neither.
    it 'asks for anonymous privacy and a default-enabled course-navigation placement' do
      get '/lti/legacy/config.xml'
      expect(response.body)
        .to include('<lticm:property name="privacy_level">anonymous</lticm:property>')
      expect(response.body).to include('<lticm:options name="course_navigation">')
      expect(response.body).to include('<lticm:property name="enabled">true</lticm:property>')
      expect(response.body).to include('<lticm:property name="default">enabled</lticm:property>')
    end

    it 'carries no consumer key or secret' do
      get '/lti/legacy/config.xml'
      expect(response.body).not_to match(/consumer_key|shared_secret|secret/i)
    end

    it 'is reachable without the extension too' do
      get '/lti/legacy/config'
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/xml')
    end

    it 'is not served when legacy launches are disabled' do
      allow(Features).to receive(:lti_legacy_launches?).and_return(false)
      get '/lti/legacy/config.xml'
      expect(response).to have_http_status(:not_found)
    end

    it 'is not served when the Canvas integration is disabled' do
      allow(Features).to receive(:canvas_integration?).and_return(false)
      get '/lti/legacy/config.xml'
      expect(response).to have_http_status(:not_found)
    end
  end
end
