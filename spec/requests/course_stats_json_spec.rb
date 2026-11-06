# frozen_string_literal: true

require 'rails_helper'

describe 'Course stats in course.json', type: :request do
  let(:course) { create(:course, slug: 'School/Course_stats_(Fall_2026)') }
  let(:stored_edit_counts) do
    { 'edits_by_namespace' => { 0 => 7 }, 'edits_by_wiki' => { 1 => 9 } }
  end

  def course_stats
    get "/courses/#{course.slug}/course.json"
    JSON.parse(response.body).dig('course', 'course_stats')
  end

  it 'leaves the stored edit counts out of the overview stats' do
    namespace_stats = { 'en.wikipedia.org-namespace-0' => { edited_count: 3 } }
    create(:course_stats, course:, stats_hash: namespace_stats.merge(stored_edit_counts))
    expect(course_stats['stats_hash'].keys).to eq(['en.wikipedia.org-namespace-0'])
  end

  it 'sends no course stats when only the stored edit counts exist' do
    create(:course_stats, course:, stats_hash: stored_edit_counts)
    expect(course_stats).to be_nil
  end
end
