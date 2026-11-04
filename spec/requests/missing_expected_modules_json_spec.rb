# frozen_string_literal: true

require 'rails_helper'

describe 'Missing expected modules in course.json', type: :request do
  let(:course) { create(:course, slug: 'School/Expected_modules_(Fall_2026)') }
  let(:week) { create(:week, course:) }

  def course_data
    get "/courses/#{course.slug}/course.json"
    JSON.parse(response.body)['course']
  end

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    TrainingModule.load_all
    Tag.create(course_id: course.id, key: 'index', tag: 'research_write_assignment')
    create(:block, week:, training_module_ids: [1, 28, 7, 71, 15, 72, 73, 64])
  end

  it 'lists missing expected modules by name for admins' do
    login_as create(:admin, wiki_token: 'token')
    expect(course_data['missing_expected_modules']).to eq([])
    Block.update_all(training_module_ids: [1, 28, 7, 71, 72, 73, 64])
    expect(course_data['missing_expected_modules']).to eq([['Plagiarism']])
  end

  it 'leaves them out for non-admins' do
    login_as create(:user)
    expect(course_data).not_to have_key('missing_expected_modules')
  end
end
