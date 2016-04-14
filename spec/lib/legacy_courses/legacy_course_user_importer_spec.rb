require 'rails_helper'
require "#{Rails.root}/lib/legacy_courses/legacy_course_user_importer"
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"

describe LegacyCourseUserImporter do
  describe '.add_users' do
    it 'should add users based on course data' do
      VCR.use_cassette 'wiki/add_users' do
        course = create(:course,
                        id: 351)
        data = LegacyCourseImporter.get_course_info 351
        student_data = data[0]['participants']['student']
        LegacyCourseUserImporter.add_users(student_data, 0, course)
        expect(course.students.all.count).to eq(12)
      end
    end
  end
end
