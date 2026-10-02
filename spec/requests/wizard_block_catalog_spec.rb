# frozen_string_literal: true

require 'rails_helper'

# The two admin-only endpoints behind the timeline's standard-block picker and
# its sandbox mode switcher.
describe 'Wizard block catalog and sandbox mode', type: :request do
  let(:course) { create(:course, slug: 'School/Course_(Term)', flags: {}) }
  let(:admin) { create(:admin) }
  let(:instructor) { create(:user) }

  before do
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  describe 'GET /wizards/:wizard_id/blocks' do
    it 'returns the catalog with a match verdict per block' do
      login_as admin
      get "/wizards/researchwrite/blocks.json?course_id=#{CGI.escape(course.slug)}"
      body = Oj.load(response.body)
      expect(body['blocks'].count).to eq(45)
      entry = body['blocks'].find { |block| block['id'] == 'keeping_track_sandboxes' }
      expect(entry['match']).to eq('yes')
      expect(entry['title']).to eq('Keeping track of your work')
    end

    it 'reports :unknown for blocks whose wizard answer was never persisted' do
      login_as admin
      get "/wizards/researchwrite/blocks.json?course_id=#{CGI.escape(course.slug)}"
      body = Oj.load(response.body)
      entry = body['blocks'].find { |block| block['id'] == 'copyedit' }
      expect(entry['match']).to eq('unknown')
      expect(body['unknown_logic_keys']).to include('copyedit')
    end

    it 'flags blocks whose title is already in the timeline' do
      week = create(:week, course:, order: 1)
      create(:block, week:, title: 'Evaluate Wikipedia', order: 1)
      login_as admin
      get "/wizards/researchwrite/blocks.json?course_id=#{CGI.escape(course.slug)}"
      body = Oj.load(response.body)
      entry = body['blocks'].find { |block| block['id'] == 'evaluate_wikipedia' }
      expect(entry['in_timeline']).to be true
    end

    it '404s for a wizard that does not exist' do
      login_as admin
      get "/wizards/nope/blocks.json?course_id=#{CGI.escape(course.slug)}"
      expect(response).to have_http_status(:not_found)
    end

    it 'is not available to a non-admin instructor of the course' do
      login_as instructor
      get "/wizards/researchwrite/blocks.json?course_id=#{CGI.escape(course.slug)}"
      expect(response).not_to have_http_status(:ok)
    end
  end

  describe 'POST /courses/:course_id/sandbox_mode' do
    it 'switches the course and reports what changed' do
      week = create(:week, course:, order: 1)
      create(:block, week:, title: 'Keeping track of your work', order: 1)
      login_as admin
      post "/courses/#{course.slug}/sandbox_mode.json",
           params: { no_sandboxes: true }.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }
      body = Oj.load(response.body)
      expect(body['no_sandboxes']).to be true
      expect(body['removed'].map { |b| b['catalog_id'] }).to include('keeping_track_sandboxes')
      expect(course.reload.no_sandboxes?).to be true
    end

    it 'is not available to a non-admin instructor of the course' do
      login_as instructor
      post "/courses/#{course.slug}/sandbox_mode.json",
           params: { no_sandboxes: true }.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }
      expect(response).not_to have_http_status(:ok)
      expect(course.reload.no_sandboxes?).to be false
    end
  end
end
