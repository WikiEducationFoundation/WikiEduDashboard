# frozen_string_literal: true
require 'rails_helper'

describe RevisionFeedbackController do
  describe '#index' do
    # The pageid is arbitrary and tests if valid feedback is received
    let(:params) { { 'title': 'Quantum_Chemistry' } }

    context 'When the article exists' do
      before do
        VCR.use_cassette 'ores_features' do
          get :index, params: params
        end
      end

      it 'renders without error' do
        expect(response.status).to eq(200)
      end

      it 'calls RevisionFeedbackService with features' do
        VCR.use_cassette 'ores_features' do

          # Checks if the RevisionFeedbackService is initialized with valid features
          expect_any_instance_of(RevisionFeedbackService).to receive(:initialize)
            .with(have_key('feature.enwiki.revision.cite_templates'))

          # Checks if a valid feedback is received from RevisionFeedbackService
          expect_any_instance_of(RevisionFeedbackService).to receive(:feedback)
            .and_return(have_at_least(1))
          get :index, params: params
        end
      end

      it 'assigns valid feedback' do
        feedback = assigns(:feedback)
        expect(feedback.length).to be >= 1
      end
    end
  end
end
