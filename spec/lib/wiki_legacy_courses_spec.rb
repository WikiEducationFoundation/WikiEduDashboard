require 'rails_helper'
require "#{Rails.root}/lib/legacy_courses/wiki_legacy_courses"

describe WikiLegacyCourses do
  it 'should return course info for an existing course' do
    VCR.use_cassette 'wiki_legacy_courses/single_course' do
      # A single course
      # rubocop:disable Metrics/LineLength
      response = WikiLegacyCourses.get_course_info 351
      expect(response[0]['course']['title']).to eq('HSCI 3013: History of Science to the Age of Newton')
      expect(response[0]['course']['term']).to eq('Summer 2014')
      expect(response[0]['course']['slug']).to eq('University_of_Oklahoma/HSCI_3013:_History_of_Science_to_the_Age_of_Newton_(Summer_2014)')
      expect(response[0]['course']['school']).to eq('University of Oklahoma')
      expect(response[0]['course']['start']).to eq('2014-05-12'.to_date)
      expect(response[0]['course']['end']).to eq('2014-06-25'.to_date)
      # rubocop:enable Metrics/LineLength
    end
  end

  it 'should handle a nonexistent course' do
    VCR.use_cassette 'wiki_legacy_courses/no_course' do
      # A single course that doesn't exist
      response = WikiLegacyCourses.get_course_info 2155897
      expect(response).to eq([])
    end
  end

  it 'should return course info for multiple courses' do
    VCR.use_cassette 'wiki_legacy_courses/missing_courses' do
      # Several courses, including some that don't exist
      course_ids = [9999, 351, 366, 398, 2155897, 411, 415, 9999]
      response = WikiLegacyCourses.get_course_info course_ids
      expect(response).not_to be_nil
    end
  end
end
