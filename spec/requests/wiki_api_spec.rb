require 'rails_helper'
require "#{Rails.root}/lib/wiki"

RSpec.describe 'Wiki API' do
  it 'should return liststudents API results for a course' do
    VCR.use_cassette 'wiki/liststudents_api' do
      response = WikiLegacyCourses.get_course_info_raw(516)
      expect(response['0']['instructors']).not_to be_nil
      expect(response['0']['campus_volunteers']).not_to be_nil
      expect(response['0']['online_volunteers']).not_to be_nil
      expect(response['0']['students']).not_to be_nil
    end
  end
end
