require 'rails_helper'
require 'media_wiki'

describe Course, :type => :model do

  it 'should get data for a course' do
    VCR.use_cassette 'course/data' do
      course = build(:course)
      raw_id = { hash: course.id }
      data = Wiki.get_course_info raw_id
      Course.import_courses(raw_id, data)
      Course.update_all_courses
    end
  end

  it 'should ?' do
    course = build(:course)
    puts course.to_param
  end

  it 'should update the participants in a course' do
    VCR.use_cassette 'course/update' do
      course = build(:course)
      course.update
    end
  end

  it 'should return the students in the course' do
  end
end
