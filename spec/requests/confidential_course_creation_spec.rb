# frozen_string_literal: true

require 'rails_helper'

# The wire from the course creator's privacy-mode checkbox through to an
# obfuscated course.
describe 'Creating a privacy-mode course', type: :request do
  let(:instructor) { create(:user, username: 'Instructor') }
  let(:course_params) do
    { title: 'Introduction to Biology', school: 'State University', term: 'Fall 2026',
      start: '2026-08-24', end: '2026-12-11', subject: 'Biology', expected_students: 20,
      home_wiki: { language: 'en', project: 'wikipedia' } }
  end

  before do
    stub_wiki_validation
    login_as instructor
  end

  it 'obfuscates the course when the checkbox is ticked' do
    post '/courses.json', params: { course: course_params.merge(confidential: true) }
    course = Course.last
    expect(course).to be_confidential
    expect(course.title).not_to include('Biology')
    expect(course.school).not_to include('State University')
    expect(course.slug).not_to include('Biology')
  end

  it 'keeps the real values in the admin-only record' do
    post '/courses.json', params: { course: course_params.merge(confidential: true) }
    detail = Course.last.confidential_course_detail
    expect(detail.real_title).to eq('Introduction to Biology')
    expect(detail.real_school).to eq('State University')
  end

  it 'returns the obfuscated slug, which is where the creator redirects' do
    post '/courses.json', params: { course: course_params.merge(confidential: true) }
    expect(response.parsed_body['course']['slug']).to eq(Course.last.slug)
    expect(response.parsed_body['course']['slug']).not_to include('Biology')
  end

  it 'leaves the course alone when the checkbox is not ticked' do
    post '/courses.json', params: { course: course_params }
    course = Course.last
    expect(course).not_to be_confidential
    expect(course.title).to eq('Introduction to Biology')
  end

  it 'treats an unticked checkbox value as not confidential' do
    post '/courses.json', params: { course: course_params.merge(confidential: false) }
    expect(Course.last).not_to be_confidential
  end

  it 'ignores the checkbox on the Programs & Events Dashboard' do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    post '/courses.json', params: { course: course_params.merge(confidential: true) }
    course = Course.last
    expect(course).not_to be_confidential
    expect(course.title).to eq('Introduction to Biology')
  end
end
