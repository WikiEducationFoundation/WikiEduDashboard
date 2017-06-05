# frozen_string_literal: true
require 'rails_helper'

describe RevisionFeedbackController do
  describe '#index' do
    let(:params) { { article_id: 1 } }
    let(:article) { build(:article, { mw_page_id: 27697087, id: 1 }) }

    context 'When the article exists' do
      before do
        VCR.use_cassette 'ores_features' do
          article.save
          get :index, params: params
        end
      end

      it 'renders without error' do
        expect(response.status).to eq(200)
      end

      # TODO : Check if the feedback is valid if article exists
    end
  end
end
