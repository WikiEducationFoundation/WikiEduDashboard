require 'rails_helper'

describe Wiki do
  describe 'API requests' do
    it 'should return the content of a page' do
      VCR.use_cassette 'wiki/course_list' do
        title = 'Wikipedia:Education program/Dashboard/test_ids'
        response = Wiki.get_page_content(title)
        expect(response).to eq("439\n456\n351")
      end
    end

    it 'should return course info for a certain course' do
      VCR.use_cassette 'wiki/course_data' do
        # A single course
        # rubocop:disable Metrics/LineLength
        response = Wiki.get_course_info '351'
        expect(response[0]['course']['title']).to eq('HSCI 3013: History of Science to the Age of Newton')
        expect(response[0]['course']['term']).to eq('Summer 2014')
        expect(response[0]['course']['slug']).to eq('University_of_Oklahoma/HSCI_3013:_History_of_Science_to_the_Age_of_Newton_(Summer_2014)')
        expect(response[0]['course']['school']).to eq('University of Oklahoma')
        expect(response[0]['course']['start']).to eq('2014-05-12'.to_date)
        expect(response[0]['course']['end']).to eq('2014-06-25'.to_date)
        # rubocop:enable Metrics/LineLength

        # Several courses, including some that don't exist
        course_ids = %w( 9999 351 366 398 2155897 411 415 9999 )
        response = Wiki.get_course_info course_ids
        expect(response).to be

        # A single course that doesn't exist
        response = Wiki.get_course_info '2155897'
        expect(response).to eq([])
      end
    end

    it 'should handle unknown gateway login errors' do
      stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*})
        .to_raise(StandardError)
      Wiki.send(:gateway)
    end

    it 'should handle MediaWiki API errors' do    
      VCR.use_cassette 'wiki/mediawiki_errors' do
        @mw = Wiki.send(:gateway)
      end
    
      stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*})
        .to_raise(MediaWiki::APIError.new('foo', 'bar'))

      options = { 'action' => 'liststudents',
                  'courseids' => '351',
                  'group' => ''
                }
      response = Wiki.send(:api_get, options, @mw)
      expect(response).to be_nil
      
      stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*})
        .to_raise(StandardError)
      response = Wiki.send(:api_get, options, @mw)
      expect(response).to be_nil
    end
  end

  describe 'API response parsing' do
    it 'should return the list of courses' do
      VCR.use_cassette 'wiki/course_list' do
        create(:cohort)
        response = Wiki.course_list
        expect(response.count).to be >= 1
      end
    end
  end

  describe 'API article ratings' do
    it 'should return the ratings of articles' do
      VCR.use_cassette 'wiki/article_ratings' do
        # A single article
        response = Wiki.get_article_rating('History of biology')
        expect(response[0]['History of biology']).to eq('fa')

        # A single non-existant article
        response = Wiki.get_article_rating('THIS IS NOT A REAL ARTICLE TITLE')
        expect(response[0]['THIS IS NOT A REAL ARTICLE TITLE']).to eq(nil)

        # A mix of existing and non-existant, including ones with niche ratings.
        # Some of these ratings may change over time.
        # rubocop:disable Metrics/LineLength
        articles = [
          'History of biology', # fa
          'A Clash of Kings', # c
          'Ecology', # ga
          'Fast inverse square root', # ga
          'Nansenflua', # unassessed
          'List of Oregon ballot measures', # list
          'The American Monomyth', # stub
          'Drug Trafficking Safe Harbor Elimination Act', # start
          'Energy policy of the United States', # b
          'List of camouflage methods', # fl
          'THIS IS NOT A REAL ARTICLE TITLE', # does not exist
          '1804 Snow hurricane', # a/ga ?
          'Barton S. Alexander', # a
          'Actuarial science', # bplus
          'List of Canadian plants by family S', # sl
          'Antarctica (disambiguation)', # dab
          '2015 Pacific typhoon season', # cur, as of 2015-02-27
          "Cycling at the 2016 Summer Olympics – Men's Omnium", # future, as of 2015-02-27
          'Selfie (disambiguation)', # no talk page
          'Sex trafficking' # blank talk page
        ]
        # rubocop:enable Metrics/LineLength

        response = Wiki.get_article_rating(articles)
        expect(response).to include('History of biology' => 'fa')
        expect(response).to include('THIS IS NOT A REAL ARTICLE TITLE' => nil)
        expect(response.count).to eq(20)
      end
    end

    it 'should return the raw page contents' do
      VCR.use_cassette 'wiki/article_ratings_raw' do
        # rubocop:disable Metrics/LineLength
        articles = [
          'Talk:Selfie (disambiguation)', # probably doesn't exist; the corresponding article does
          'Talk:The American Monomyth', # exists
          'Talk:THIS PAGE WILL NEVER EXIST, RIGHT?', # definitely doesn't exist
          'Talk:List of Canadian plants by family S' # exists
        ]
        # rubocop:enable Metrics/LineLength
        response = Wiki.get_article_rating_raw(articles)
        expect(response.count).to eq(4)
      end
    end
  end
end
