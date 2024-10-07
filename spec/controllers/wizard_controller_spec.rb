# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WizardController, type: :controller do
  describe 'GET #wizard_index' do
    it 'returns the content as JSON' do
      expected_yaml = { 'step' => 'Race the Block', 'details' => 'Get Running Shoes' }
      content_path = "#{Rails.root}/config/wizard/wizard_index.yml"
      allow(File).to receive(:read).with(File.expand_path(content_path,
                                                          __FILE__)).and_return(expected_yaml.to_yaml)

      get :wizard_index, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to eq(expected_yaml.stringify_keys)
    end
  end
end
