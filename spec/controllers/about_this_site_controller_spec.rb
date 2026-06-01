# frozen_string_literal: true

require 'rails_helper'

describe AboutThisSiteController, type: :request do
  describe '#private_information' do
    it 'renders privacy-related info' do
      get '/private_information'
      expect(response.status).to eq(200)
      expect(response.body).to include('Private Information')
    end
  end

  describe '#accessibility' do
    it 'renders the VPAT from the Markdown source, with tables' do
      get '/accessibility'
      expect(response.status).to eq(200)
      expect(response.body).to include('Voluntary Product Accessibility Template')
      expect(response.body).to include('<table>')
      expect(response.body).to include('Success Criteria, Level AA')
    end

    it 'is not served on the P&E Dashboard deployment' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/accessibility'
      expect(response.status).to eq(404)
    end
  end
end
