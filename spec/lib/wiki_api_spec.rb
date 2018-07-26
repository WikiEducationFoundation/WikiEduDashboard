# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_api"

describe WikiApi do
  describe 'error handling' do
    let(:subject) { WikiApi.new.get_page_content('Ragesoss') }

    it 'handles mediawiki 503 errors gracefully' do
      stub_wikipedia_503_error
      expect(subject).to eq(nil)
    end

    it 'handles timeout errors gracefully' do
      allow_any_instance_of(MediawikiApi::Client).to receive(:send)
        .and_raise(Faraday::TimeoutError)
      expect(subject).to eq(nil)
    end

    it 'handles API errors gracefully' do
      allow_any_instance_of(MediawikiApi::Client).to receive(:send)
        .and_raise(MediawikiApi::ApiError)
      expect(subject).to eq(nil)
    end

    it 'handles HTTP errors gracefully' do
      allow_any_instance_of(MediawikiApi::Client).to receive(:send)
        .and_raise(MediawikiApi::HttpError, '')
      expect(subject).to eq(nil)
    end

    it 're-raises unexpected errors' do
      class UnexpectedError < StandardError; end
      allow_any_instance_of(MediawikiApi::Client).to receive(:send)
        .and_raise(UnexpectedError)
      expect { subject }.to raise_error(UnexpectedError)
    end
  end
  describe '#get_page_content' do
    it 'returns the content of a page' do
      VCR.use_cassette 'wiki/course_list' do
        title = 'Wikipedia:Education program/Dashboard/test_ids'
        response = WikiApi.new.get_page_content(title)
        expect(response).to eq("439\n456\n351")
      end
    end

    # This is really a test that Used#talk_page is returning the format
    # expected by the API, and not a URL-encoded page title.
    it 'gets the content of a user talk page with special characters' do
      user = build(:user, username: 'Julie209!')
      VCR.use_cassette 'wiki/user_talk' do
        response = WikiApi.new.get_page_content(user.talk_page)
        expect(response).not_to be_blank
      end
    end
  end

  describe '#fetch_all' do
    it 'returns the same data as a single complete query would' do
      VCR.use_cassette 'wiki/continue_response' do
        titles = %(apple Fruit ecosystem Pear)
        # With a low palimit, this query will need to continue
        continue_query = { titles: titles,
                           prop: 'pageassessments',
                           redirects: 'true',
                           palimit: 2 }
        # With a high palimit, this query will not need to continue
        complete_query = continue_query.merge(palimit: 50)
        complete = WikiApi.new.send(:fetch_all, complete_query)
        continue = WikiApi.new.send(:fetch_all, continue_query)
        expect(complete).to eq(continue)
      end
    end
  end

  describe '#get_article_ratings' do
    it 'returns the ratings of articles' do
      VCR.use_cassette 'wiki/article_ratings' do
        # A single article
        response = WikiApi.new.get_article_rating('History_of_biology')
        expect(response['History_of_biology']).to eq('fa')

        # A single non-existant article
        response = WikiApi.new.get_article_rating('THIS_IS_NOT_A_REAL_ARTICLE_TITLE')
        expect(response['THIS_IS_NOT_A_REAL_ARTICLE_TITLE']).to eq(nil)

        # A mix of existing and non-existant, including ones with niche ratings.
        # Some of these ratings may change over time.
        articles = [
          'History_of_biology', # fa
          'A_Clash_of_Kings', # c
          'Ecology', # ga
          'Fast_inverse_square_root', # ga
          'Nansenflua', # unassessed
          'List_of_Oregon_ballot_measures', # list
          'The_American_Monomyth', # stub
          'Drug_Trafficking_Safe_Harbor_Elimination_Act', # start
          'Energy_policy_of_the_United_States', # b
          'List_of_camouflage_methods', # fl
          'THIS_IS_NOT_A_REAL_ARTICLE_TITLE', # does not exist
          '1804_Snow_hurricane', # a
          'Barton_S._Alexander', # a
          'Bell_number', # b, formerly bplus
          'List_of_Canadian_plants_by_family_S', # sl
          'Antarctica_(disambiguation)', # disambig
          '2015_Pacific_typhoon_season', # start
          'Sex_trafficking', # c
          'American_Civil_War_prison_camps' # cl
        ]

        response = WikiApi.new.get_article_rating(articles)
        expect(response['History_of_biology']).to eq('fa')
        expect(response['THIS_IS_NOT_A_REAL_ARTICLE_TITLE']).to eq(nil)
        expect(response['American_Civil_War_prison_camps']).to eq('cl')
        expect(response['Bell_number']).to eq('b')
        expect(response['Nansenflua']).to eq(nil)
      end
    end
  end

  describe '#get_user_id' do
    context 'for an English Wikipedia users' do
      let(:wiki) { Wiki.new(language: 'en', project: 'wikipedia') }

      it 'returns the correct user_id for all types of usernames' do
        usernames = { 'Ragesoss' => 319203,
                      'LiAnna (Wiki Ed)' => 21102089, # spaces and parens
                      'ערן' => 7201119, # Hebrew characters
                      'JRicker,PhD' => 17137867, # comma
                      'Evol&Glass' => 22403865, # ampersand
                      "Jack's nomadic mind" => 26211578, # apostrophe
                      '!!Aaapplesauce' => 11274650 } # exclamation

        VCR.use_cassette 'wiki/get_user_id_en_wiki' do
          usernames.each do |username, id|
            result = WikiApi.new(wiki).get_user_id(username)
            expect(result).to eq(id)
          end
        end
      end
    end

    context 'for a Spanish Wikipedia user' do
      let(:wiki) { Wiki.new(language: 'es', project: 'wikipedia') }
      let(:username) { 'Ragesoss' }

      it 'returns the correct user_id' do
        VCR.use_cassette 'wiki/get_user_id_es_wiki' do
          result = WikiApi.new(wiki).get_user_id(username)
          expect(result).to eq(772153)
        end
      end
    end

    it 'returns nil for usernames that do not exist' do
      VCR.use_cassette 'wiki/get_user_id_nonexistent' do
        username = 'RagesossRagesossRagesoss'
        user_id = WikiApi.new.get_user_id(username)
        expect(user_id).to be_nil
      end
    end
  end

  describe '#redirect?' do
    let(:wiki) { Wiki.new(language: 'en', project: 'wikipedia') }
    let(:subject) { WikiApi.new(wiki).redirect?(title) }

    context 'when title is a redirect' do
      let(:title) { 'Athletics_in_Epic_Poetry' }
      it 'returns true' do
        VCR.use_cassette 'wiki/redirect' do
          expect(subject).to eq(true)
        end
      end
    end

    context 'when title is not a redirect' do
      let(:title) { 'Selfie' }
      it 'returns false' do
        VCR.use_cassette 'wiki/redirect' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when title does not exist' do
      let(:title) { 'THIS_PAGE_DOES_NOT_EXIST' }
      it 'returns false' do
        VCR.use_cassette 'wiki/redirect' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when no data is returned' do
      let(:title) { 'Athletics_in_Epic_Poetry' }
      it 'returns false' do
        stub_request(:any, /.*/).to_return(status: 200, body: '{}', headers: {})
        expect(subject).to eq(false)
      end
    end
  end
end
