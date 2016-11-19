# frozen_string_literal: true
require 'rails_helper'

describe FeedbackFormResponse do
  let(:response) { create(:feedback_form_response, subject: subject) }

  describe '#topic' do
    context 'when subject is a training url' do
      let(:subject) do
        'https://dashboard.wikiedu.org/training/students/editing-basics/be-bold-tutorial'
      end
      it 'extracts the module from training url' do
        expect(response.topic).to eq('editing-basics')
      end
    end

    context 'when subject is an arbitrary string' do
      let(:subject) { 'Diff Viewer' }
      it 'returns the subject' do
        expect(response.topic).to eq(subject)
      end
    end
  end
end
