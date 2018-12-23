# frozen_string_literal: true

require 'rails_helper'

describe AskController, type: :request do
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
  end

  describe '#search' do
    let(:subject) { get '/ask', params: query }

    context 'when query is not blank' do
      let(:query) { { q: 'Help! I cannot enroll!' } }

      it 'redirects to ask.wikiedu.org for a search' do
        expect(subject).to redirect_to(/.*ask\.wikiedu\.org\.*/)
      end
    end

    context 'when query is blank' do
      let(:query) { { q: '' } }

      it 'redirects to ask.wikiedu.org homepage for empty query' do
        expect(subject).to redirect_to(/.*ask\.wikiedu\.org.*/)
      end
    end
  end
end
