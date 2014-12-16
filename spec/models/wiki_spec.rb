require 'rails_helper'

describe Wiki do

  describe "API requests" do
    it "should return course info for a certain course" do
      VCR.use_cassette "wiki/course_data" do
        response = Wiki.get_course_info 366
        expect(response["name"]).to eq("Brock University/NUSC 1P10 Professional and Therapeutic Communications (Fall 2014)")
        expect(response["start"]).to eq("2014-08-01")
        expect(response["end"]).to eq("2014-12-31")
      end
    end

    it "should return student enrollment data for a certain course" do
      VCR.use_cassette "wiki/student_data" do
        response = Wiki.get_student_list 366
        expect(response).to_not be_empty
      end
    end

    it "should return revision data for a certain article and user" do
      VCR.use_cassette "wiki/revision_data" do
        response = Wiki.get_revision_data 'History of biology', 'Ragesoss'
        expect(response).to_not be_empty
      end
    end
  end

  describe "API response parsing" do

    it "should return the number of students in a course" do
      VCR.use_cassette "wiki/student_data" do
        response = Wiki.get_student_count_in_course 366
        expect(response).to eq(77)
      end
    end

    it "should list all students in a course" do
      VCR.use_cassette "wiki/student_data" do
        response = Wiki.get_students_in_course 366
        expect(response).to include("Mattclare")
      end
    end

    it "should return the earliest article revision made by a user" do
      VCR.use_cassette "wiki/revision_data" do
        response = Wiki.get_user_first_revision_to_article "History of biology", "Ragesoss"
        expect(response["user"]).to eq("Ragesoss")
        expect(response["timestamp"]).to eq("2007-05-17T04:56:25Z")
        expect(response["comment"]).to include("versions of the same interwiki link")
      end
    end

  end

  describe "Public methods" do

  end

end