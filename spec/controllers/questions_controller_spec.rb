# frozen_string_literal: true

require 'rails_helper'

describe QuestionsController, type: :request do
  describe '#question' do
    context 'when the question exists' do
      let!(:question) { create(:q_checkbox) }
      let(:question_id) { question.id }

      before do
        params = { id: question_id, format: :json }
        get "/surveys/question_group_question/#{question_id}", params:
      end

      it 'renders the question in json' do
        expect(Oj.load(response.body)['question']['id']).to eq(question.id)
      end
    end
  end

  describe '#update_position' do
    context 'when the question exists' do
      let!(:question) { create(:q_checkbox, position: 1) }
      let(:question_id) { question.id }

      before do
        params = { id: question_id, position: 50 }
        put '/surveys/question_position', params:
      end

      it 'updates the postion' do
        expect(Rapidfire::Question.last.position).to eq(50)
      end
    end
  end
end
