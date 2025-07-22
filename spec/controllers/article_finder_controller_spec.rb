# frozen_string_literal: true

require 'rails_helper'

describe ArticleFinderController, type: :request do
  describe 'index' do
    it 'renders' do
      get '/article_finder'
      expect(response.status).to eq(200)
    end
  end
end
