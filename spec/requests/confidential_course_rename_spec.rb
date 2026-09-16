# frozen_string_literal: true

require 'rails_helper'

# The obfuscated title and school are what keep a privacy-mode course anonymous,
# and its slug is already published on-wiki, so neither can be edited.
describe 'Renaming a privacy-mode course', type: :request do
  let(:course) do
    create(:course, title: obfuscated_title, school: obfuscated_school, term: 'Fall 2026',
                    slug: obfuscated_slug('Fall 2026'))
  end
  let(:admin) { create(:admin, username: 'Admin') }

  before do
    create(:confidential_course_detail, course:)
    login_as admin
  end

  it 'refuses a change to the title' do
    put "/courses/#{course.slug}.json",
        params: { id: course.slug, course: { title: 'Introduction to Biology' } }
    expect(response).to have_http_status(:conflict)
    expect(course.reload.title).to eq(obfuscated_title)
  end

  it 'refuses a change to the school' do
    put "/courses/#{course.slug}.json",
        params: { id: course.slug, course: { school: 'State University' } }
    expect(response).to have_http_status(:conflict)
    expect(course.reload.school).to eq(obfuscated_school)
  end

  it 'leaves the slug alone' do
    put "/courses/#{course.slug}.json",
        params: { id: course.slug, course: { title: 'Introduction to Biology',
                                             school: 'State University' } }
    expect(course.reload.slug).to eq(obfuscated_slug('Fall 2026'))
  end

  it 'still allows edits to fields that are not confidential' do
    put "/courses/#{course.slug}.json",
        params: { id: course.slug, course: { description: 'A new description' } }
    expect(response).to have_http_status(:success)
    expect(course.reload.description).to eq('A new description')
  end

  it 'does not interfere with renaming an ordinary course' do
    ordinary = create(:course, title: 'Ordinary', school: 'Open U', term: 'Fall 2026',
                               slug: 'Open_U/Ordinary_(Fall_2026)')
    put "/courses/#{ordinary.slug}.json",
        params: { id: ordinary.slug, course: { title: 'Renamed', school: 'Open U' } }
    expect(ordinary.reload.title).to eq('Renamed')
  end
end
