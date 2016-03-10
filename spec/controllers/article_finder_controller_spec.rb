require 'rails_helper'

describe ArticleFinderController do
  describe 'index' do
    it 'renders' do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe 'results' do
    it 'handles empty submissions' do
      post :results
      expect(CategoryImporter).not_to receive(:show_category)
      expect(response.status).to eq(200)
    end

    it 'invokes CategoryImporter' do
      params = { category: 'Feminism' }
      expect(CategoryImporter).to receive(:show_category)
      post :results, params
      expect(response.status).to eq(200)
    end
  end
end
