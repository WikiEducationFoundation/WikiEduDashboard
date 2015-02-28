require 'rails_helper'

describe Wiki do

  describe "API requests" do
    it "should return the content of a page" do
      VCR.use_cassette "wiki/course_list" do
        response = Wiki.get_page_content('Wikipedia:Education program/Dashboard/test_ids')
        expect(response).to eq("439\n456\n351")

      end
    end

    it "should return course info for a certain course" do
      VCR.use_cassette "wiki/course_data" do

        # A single course
        response = Wiki.get_course_info '351'
        expect(response[0]["course"]["title"]).to eq("HSCI 3013: History of Science to the Age of Newton")
        expect(response[0]["course"]["term"]).to eq("Summer 2014")
        expect(response[0]["course"]["slug"]).to eq("University_of_Oklahoma/HSCI_3013:_History_of_Science_to_the_Age_of_Newton_(Summer_2014)")
        expect(response[0]["course"]["school"]).to eq("University of Oklahoma")
        expect(response[0]["course"]["start"]).to eq("2014-05-12".to_date)
        expect(response[0]["course"]["end"]).to eq("2014-06-25".to_date)

        # Several courses, including some that don't exist
        course_ids = [ '9999', '351', '366', '398', '2155897', '411', '415', '9999' ]
        response = Wiki.get_course_info course_ids
        expect(response).to be

        # A single course that doesn't exist
        response = Wiki.get_course_info '2155897'
        expect(response).to eq([])
      end
    end
  end


  describe "API response parsing" do
    it "should return the list of courses" do
      VCR.use_cassette "wiki/course_list" do
        response = Wiki.get_course_list
        expect(response.count).to be >= 1
      end
    end
  end

  describe "API article ratings" do
    it "should return the ratings of articles" do
      VCR.use_cassette "wiki/article_ratings" do
        # A single article
        response = Wiki.get_article_rating("History of biology")
        expect(response[0]["History of biology"]).to eq("fa")

        # Articles that exist, including ones with niche ratings
        # Some of these ratings may change over time.
        articles = [
          "History of biology", # fa
          "Selfie", # c
          "Ecology", # ga
          "Fast inverse square root", # ga
          "Nansenflua", # unassessed
          "List of Oregon ballot measures", # list
          "The American Monomyth", # stub
          "Drug Trafficking Safe Harbor Elimination Act", # start
          "Energy policy of the United States", # b
          "List of camouflage methods", # fl
          "THIS IS NOT A REAL ARTICLE TITLE", # does not exist
          "1804 Snow hurricane", # a/ga ?
          "Barton S. Alexander", # a
          "Actuarial science", # bplus
          "List of Canadian plants by family S", # sl
          "Antarctica (disambiguation)", # dab
          "2015 Pacific typhoon season", # cur, as of 2015-02-27
          "Cycling at the 2016 Summer Olympics – Men's Omnium", # future, as of 2015-02-27
          "Selfie (disambiguation)" # no talk page
        ]

        response = Wiki.get_article_rating(articles)
        expect(response).to include({"History of biology"=>"fa"})
        expect(response).to include({"THIS IS NOT A REAL ARTICLE TITLE"=>nil})
        expect(response.count).to eq(19)

      end
    end

    it "should return the raw page contents" do
      VCR.use_cassette "wiki/article_ratings_raw" do
        articles = [
          "Talk:Selfie (disambiguation)", # probably doesn't exist; the corresponding article does
          "Talk:The American Monomyth", # exists
          "Talk:THIS PAGE WILL NEVER EXIST, RIGHT?", # definitely doesn't exist
          "Talk:List of Canadian plants by family S" # exists
        ]
        response = Wiki.get_article_rating_raw(articles)
        expect(response.count).to eq(4)
      end
    end

  end

  describe "Public methods" do

  end

end
