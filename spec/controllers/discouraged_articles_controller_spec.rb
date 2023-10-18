# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscouragedArticlesController, type: :controller do
  describe 'GET #category_member?' do
    it 'returns true when a category member exists' do
      FactoryBot.create(:wikipedia_category_member, category_member: 'Example Article')
      get :category_member?, params: { article_title: 'Example Article' }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['is_category_member']).to be_truthy
    end

    it 'returns false when a category member does not exist' do
      get :category_member?, params: { article_title: 'Nonexistent Article' }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['is_category_member']).to be_falsey
    end
  end
end
