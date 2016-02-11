require 'rails_helper'
require "#{Rails.root}/lib/wiki_api"

describe WikiApi do
  describe 'API requests' do
    it 'should return the content of a page' do
      VCR.use_cassette 'wiki/course_list' do
        title = 'Wikipedia:Education program/Dashboard/test_ids'
        response = WikiApi.get_page_content(title)
        expect(response).to eq("439\n456\n351")
      end
    end
  end

  describe 'API response parsing' do
    it 'should return the list of courses' do
      VCR.use_cassette 'wiki/course_list' do
        create(:cohort)
        response = WikiApi.course_list
        expect(response.count).to be >= 1
      end
    end
  end

  describe 'API article ratings' do
    it 'should return the ratings of articles' do
      VCR.use_cassette 'wiki/article_ratings' do
        # A single article
        response = WikiApi.get_article_rating('History_of_biology')
        expect(response[0]['History_of_biology']).to eq('fa')

        # A single non-existant article
        response = WikiApi.get_article_rating('THIS_IS_NOT_A_REAL_ARTICLE_TITLE')
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

        response = WikiApi.get_article_rating(articles)
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
        response = WikiApi.get_raw_page_content(articles)
        expect(response.count).to eq(4)
      end
    end
  end

  describe '.get_user_id' do
    it 'should take a username and return the user_id' do
      VCR.use_cassette 'wiki/get_user_id' do
        username = 'Ragesoss'
        user_id_enwiki = WikiApi.get_user_id(username)
        expect(user_id_enwiki).to eq(319203)
        user_id_eswiki = WikiApi.get_user_id(username, 'es')
        expect(user_id_eswiki).to eq(772153)
        # make sure usernames with spaces get handled correctly
        user_with_spaces = WikiApi.get_user_id('LiAnna (Wiki Ed)')
        expect(user_with_spaces).to eq(21102089)
        # make sure unicode works
        unicode_name = WikiApi.get_user_id('ערן')
        expect(unicode_name).to eq(7201119)
      end
    end

    it 'should return nil for usernames that do not exist' do
      VCR.use_cassette 'wiki/get_user_id_nonexistent' do
        username = 'RagesossRagesossRagesoss'
        user_id = WikiApi.get_user_id(username)
        expect(user_id).to be_nil
      end
    end
  end
end
