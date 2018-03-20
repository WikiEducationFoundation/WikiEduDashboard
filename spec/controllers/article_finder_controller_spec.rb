# frozen_string_literal: true

require 'rails_helper'

describe ArticleFinderController do
  if Features.enable_article_finder?
    describe 'index' do
      it 'renders' do
        get :index
        expect(response.status).to eq(200)
      end
    end

    describe 'results' do
      it 'handles empty submissions' do
        post :results
        expect(CategoryImporter).not_to receive(:new)
        expect(response.status).to eq(200)
      end

      it 'invokes CategoryImporter' do
        params = { category: 'Feminism' }
        expect_any_instance_of(CategoryImporter).to receive(:show_category)
        post :results, params: params
        expect(response.status).to eq(200)
      end
    end
  end
end
