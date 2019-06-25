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
end
