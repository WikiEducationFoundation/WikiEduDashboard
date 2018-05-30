# frozen_string_literal: true

require 'rails_helper'

describe ArticleFinderController do
  describe 'index' do
    it 'renders' do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
