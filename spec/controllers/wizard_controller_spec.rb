# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WizardController, type: :controller do
  describe 'GET #wizard_index' do
    it 'returns the content as JSON' do
      yaml_file = { 'step' => 'Race the Block', 'details' => 'Get Running Shoes' }
      content_path = "#{Rails.root}/config/wizard/wizard_index.yml"
      allow(File).to receive(:read).with(File.expand_path(content_path,
                                                          __FILE__)).and_return(yaml_file.to_yaml)

      get :wizard_index, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to eq(yaml_file.stringify_keys)
    end
  end
end
