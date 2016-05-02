require 'rails_helper'
require "#{Rails.root}/lib/wiki_api"

describe WikiApi do
  describe 'API requests' do
    it 'should return the content of a page' do
      VCR.use_cassette 'wiki/course_list' do
        title = 'Wikipedia:Education program/Dashboard/test_ids'
        response = WikiApi.new.get_page_content(title)
        expect(response).to eq("439\n456\n351")
      end
    end
  end

  describe 'API article ratings' do
    it 'should return the ratings of articles' do
      VCR.use_cassette 'wiki/article_ratings' do
        # A single article
        response = WikiApi.new.get_article_rating('History_of_biology')
        expect(response[0]['History_of_biology']).to eq('fa')

        # A single non-existant article
        response = WikiApi.new.get_article_rating('THIS_IS_NOT_A_REAL_ARTICLE_TITLE')
        expect(response[0]['THIS_IS_NOT_A_REAL_ARTICLE_TITLE']).to eq(nil)

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
          '1804_Snow_hurricane', # a/ga ?
          'Barton_S._Alexander', # a
          'Compounds_of_fluorine', # bplus
          'List_of_Canadian_plants_by_family_S', # sl
          'Antarctica_(disambiguation)', # dab
          '2015_Pacific_typhoon_season', # cur, as of 2015-02-27
          "Cycling_at_the_2016_Summer_Olympics_–_Men's_Omnium", # future, as of 2015-02-27
          'Selfie_(disambiguation)', # no talk page
          'Sex_trafficking' # blank talk page
        ]

        response = WikiApi.new.get_article_rating(articles)
        expect(response).to include('History_of_biology' => 'fa')
        expect(response).to include('THIS_IS_NOT_A_REAL_ARTICLE_TITLE' => nil)
        expect(response.count).to eq(20)
      end
    end

    it 'should return the raw page contents' do
      VCR.use_cassette 'wiki/article_ratings_raw' do
        articles = [
          'Talk:Selfie_(disambiguation)', # probably doesn't exist; the corresponding article does
          'Talk:The_American_Monomyth', # exists
          'Talk:THIS_PAGE_WILL_NEVER_EXIST,_RIGHT?', # definitely doesn't exist
          'Talk:List_of_Canadian_plants_by_family_S' # exists
        ]
        response = WikiApi.new.get_raw_page_content(articles)
        expect(response.count).to eq(4)
      end
    end
  end

  describe '.get_user_id' do
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

    it 'should return nil for usernames that do not exist' do
      VCR.use_cassette 'wiki/get_user_id_nonexistent' do
        username = 'RagesossRagesossRagesoss'
        user_id = WikiApi.new.get_user_id(username)
        expect(user_id).to be_nil
      end
    end
  end

  describe 'redirect?' do
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
