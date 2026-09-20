# frozen_string_literal: true

require 'rails_helper'

describe 'institutions:migrate' do
  include_context 'rake'

  it 'links courses with the same school name to one institution' do
    first = create(:course, id: 1, slug: 'Test/Course_One', title: 'Course One',
                            school: 'Test University')
    second = create(:course, id: 2, slug: 'Test/Course_Two', title: 'Course Two',
                             school: 'Test University')

    rake['institutions:migrate'].invoke

    expect(Institution.count).to eq(1)
    expect(first.reload.institution.name).to eq('Test University')
    expect(second.reload.institution).to eq(first.reload.institution)
  end

  it 'leaves the school text untouched' do
    course = create(:course, id: 1, school: 'Test University')
    rake['institutions:migrate'].invoke
    expect(course.reload.school).to eq('Test University')
  end

  it 'skips courses with a blank school' do
    course = create(:course, id: 1, school: '')
    rake['institutions:migrate'].invoke
    expect(course.reload.institution).to be_nil
    expect(Institution.count).to eq(0)
  end

  it 'links legacy courses that would fail their own validations' do
    course = create(:course, id: 1, school: 'Test University')
    # Simulate an old production row: no term, written straight to the database.
    course.update_column(:term, nil) # rubocop:disable Rails/SkipsModelValidations

    rake['institutions:migrate'].invoke

    expect(course.reload.institution.name).to eq('Test University')
  end
end
