require 'rails_helper'

describe Wiki do

  describe "API requests" do
    it "should return the content of a page" do
      VCR.use_cassette "wiki/course_list" do
        response = Wiki.get_page_content('Wikipedia:Education program/Dashboard/test_ids')
        expect(response).to_not be_empty
      end
    end

    it "should return course info for a certain course" do
      VCR.use_cassette "wiki/course_data" do
        response = Wiki.get_course_info 351
        expect(response["name"]).to eq("Education Program:University of Oklahoma/HSCI 3013: History of Science to the Age of Newton (Summer 2014)")
        expect(response["start"]).to eq("2014-05-12")
        expect(response["end"]).to eq("2014-06-25")
      end
    end
  end


  describe "API response parsing" do
    it "should return the list of courses" do
      VCR.use_cassette "wiki/course_list" do
        response = Wiki.get_course_list
        expect(response.count).to eq(3)
      end
    end
  end


  describe "Public methods" do

  end

end
