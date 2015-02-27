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
        course_ids = [ '351', '366', '398', '2155897', '411', '415', '99999', 'word' ]
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


  describe "Public methods" do

  end

end
