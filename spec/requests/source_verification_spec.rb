# frozen_string_literal: true

require 'rails_helper'

describe 'Source verification prototype page', type: :request do
  let(:user) { create(:user) }

  let(:example) do
    {
      id: 'abc123def456',
      claim: 'and the lighthouse was automated at the end of 1985.',
      sentence: 'The keeper retired in 1984, ' \
                'and the lighthouse was automated at the end of 1985.',
      citations: [{ ref_id: 'cite_note-1', citation_text: '"Lighthouse". Example News.',
                    source_type: 'web', url: 'https://example.com/lighthouse',
                    urls: ['https://example.com/lighthouse'], web_accessible: true }],
      article_title: 'Test Article',
      mw_page_id: 42,
      mw_rev_id: 500,
      wiki_domain: 'en.wikipedia.org'
    }
  end

  def sign_in_user
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)
  end

  describe 'GET /source_verification' do
    it 'requires a signed-in user' do
      get '/source_verification'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'serves a random example' do
      sign_in_user
      allow(SourceVerificationExampleStore).to receive(:random).and_return(example)

      get '/source_verification'

      expect(response.body).to include('The keeper retired in 1984,')
      expect(response.body)
        .to include('<mark>and the lighthouse was automated at the end of 1985.</mark>')
      expect(response.body).to include('https://example.com/lighthouse')
      expect(response.body).to include('https://en.wikipedia.org/wiki/Test_Article')
    end

    it 'serves a specific example by id' do
      sign_in_user
      allow(SourceVerificationExampleStore).to receive(:find)
        .with('abc123def456').and_return(example)

      get '/source_verification', params: { example_id: 'abc123def456' }

      expect(response.body).to include('the lighthouse was automated at the end of 1985.')
    end

    it 'renders the empty state when no examples are stored' do
      sign_in_user
      allow(SourceVerificationExampleStore).to receive(:random).and_return(nil)

      get '/source_verification'

      expect(response.body).to include('Empty-state message')
    end
  end

  describe 'POST /source_verification' do
    it 'acknowledges a submitted response for the same example' do
      sign_in_user
      allow(SourceVerificationExampleStore).to receive(:find)
        .with('abc123def456').and_return(example)

      post '/source_verification', params: { example_id: 'abc123def456',
                                             response: 'does_not_support' }

      expect(response.body).to include('the lighthouse was automated at the end of 1985.')
      expect(response.body).to include('does_not_support')
      expect(response.body).to include('Acknowledgment')
    end

    it 'ignores unknown response values' do
      sign_in_user
      allow(SourceVerificationExampleStore).to receive(:find)
        .with('abc123def456').and_return(example)

      post '/source_verification', params: { example_id: 'abc123def456',
                                             response: 'something_else' }

      expect(response.body).not_to include('Acknowledgment')
      expect(response.body).to include('The verification question')
    end
  end
end
