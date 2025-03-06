# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/tagged_courses_csv_builder"

describe TaggedCoursesCsvBuilder do
  let(:user) { create(:super_admin) }
  let(:course) { create(:course, school: 'Test University', term: 'Fall 2024') }
  let(:tag) { create(:tag, course_id: course.id) }
  let!(:courses_user) do
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end
  expected_headers = [
    'Courses',
    'Institution/Term',
    'Wiki_Expert',
    'Instructor',
    'Recent_Edits',
    'Words_Added',
    'Refrences_Added',
    'Views',
    'Editors',
    'Start_Date'
  ].join(',')

  before do
    # Associate the course with the tag
    course.tags << tag
    allow(Tag).to receive(:courses_tagged_with).with(tag).and_return([course])
  end

  let(:csv_output) { described_class.new(tag).generate_csv }

  it 'creates a CSV with the correct headers' do
    headers = csv_output.split("\n").first

    expect(headers).to eq(expected_headers)
  end

  it 'Ensure csv_Output has an extra row' do
    csv_lines = csv_output.split("\n")
    expect(csv_lines.length).to be > 1
  end

  it 'includes a row for the tagged course with correct data' do
    csv_lines = csv_output.split("\n")
    data_row = csv_lines[1] # Extract the first data row (index 1, since index 0 is the header)
    course_data = data_row.split(',')

    expect(course_data[0]).to eq(course.title)
    expect(course_data[1]).to eq("#{course.school}/#{course.term}")
    expect(course_data[2]).to eq('N/A')
    expect(course_data[4]).to eq(course.recent_revision_count.to_s)
    expect(course_data[5]).to eq(course.word_count.to_s)
    expect(course_data[6]).to eq(course.references_count.to_s)
    expect(course_data[7]).to eq(course.view_sum.to_s)
    expect(course_data[8]).to eq(course.user_count.to_s)
    expect(course_data[9]).to eq(course.start.to_date.to_s)
  end
end
