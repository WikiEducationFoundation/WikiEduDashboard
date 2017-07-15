# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_students_csv_builder"

describe CourseStudentsCsvBuilder do
  let(:course) { create(:course) }
  let(:user) { create(:user, registered_at: course.start + 1.minute) }
  let!(:courses_user) { create(:courses_user, course: course, user: user) }
  let(:subject) { described_class.new(course).generate_csv }

  it 'creates a CSV with a header and a row of data for each student' do
    expect(subject.split("\n").count).to eq(2)
    # last column is 'registered_during_project', which should be true
    # for the test user.
    expect(subject[-5..-1]).to eq("true\n")
  end
end
