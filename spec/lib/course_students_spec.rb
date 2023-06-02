# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_students"

describe CourseStudents do
  let(:course) { create(:course) }
  let(:course_students) { described_class.new(course) }

  describe '#getstudent_names' do
    context 'when there are student users in the course' do
      let!(:student1) { create(:user, username: 'student1') }
      let!(:student2) { create(:user, username: 'student2') }

      before do
        create(:courses_user, course: course, user: student1, role: CoursesUsers::Roles::STUDENT_ROLE)
        create(:courses_user, course: course, user: student2, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'returns an array of student names in the format "User:<username>"' do
        student_names = course_students.getstudent_names
        expect(student_names).to contain_exactly("User:student1", "User:student2")
      end
    end

    context 'when there are no student users in the course' do
      it 'returns an empty array' do
        student_names = course_students.getstudent_names
        expect(student_names).to be_empty
      end
    end
  end
end
