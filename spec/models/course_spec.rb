require 'rails_helper'
require 'media_wiki'

describe Course, type: :model do
  it 'should get data for a course' do
    VCR.use_cassette 'course/data' do
      course = build(:course)
      raw_id = { hash: course.id }
      data = Wiki.get_course_info course.id
      Course.import_courses(raw_id, data)
      Course.update_all_courses
    end
  end

  it 'should ?' do
    course = build(:course)
    to_param = course.to_param
  end

  it 'should update the participants in a course' do
    VCR.use_cassette 'course/update' do
      course = build(:course)
      course.update
      Course.update_all_caches
      character_sum = course.character_sum
      view_sum = course.view_sum
      user_count = course.user_count
      revision_count = course.revision_count
      untrained_count = course.untrained_count
      article_count = course.article_count
    end
  end

  describe '#url' do
    it 'should return the url of a course page' do
      course = build(:course,
                     slug: 'UW Bothell/Conservation Biology (Winter 2015)'
      )
      url = course.url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq('https://en.wikipedia.org/wiki/Education_Program:UW_Bothell/Conservation_Biology_(Winter_2015)')
      # rubocop:enable Metrics/LineLength
    end
  end

  it 'should return the students in the course' do
  end
end
