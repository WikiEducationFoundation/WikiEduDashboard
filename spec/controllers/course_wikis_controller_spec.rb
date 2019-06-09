# frozen_string_literal: true

require 'rails_helper'

describe CourseWikisController, type: :request do
  let(:course) { create(:course) }

  en_params = { course_wiki: { wikis: [{ language: 'en', project: 'wikipedia' }] } }.to_json
  fr_params = { course_wiki: { wikis: [{ language: 'fr', project: 'wikipedia' }] } }.to_json
  headers = { 'CONTENT_TYPE' => 'application/json' }

  describe '#update' do
    it 'creates the course wikis when there is none' do
      expect(course.course_wikis.count).to be(0)
      post "/course_wikis/#{course.id}/update", params: en_params, headers: headers
      expect(course.course_wikis.first.wiki.language).to eq('en')
    end

    it 'updates the course wikis' do
      post "/course_wikis/#{course.id}/update", params: en_params, headers: headers
      expect(course.course_wikis.count).to be(1)
      expect(course.course_wikis.first.wiki.language).to eq('en')

      post "/course_wikis/#{course.id}/update", params: fr_params, headers: headers
      expect(course.course_wikis.count).to be(1)
      expect(course.course_wikis.first.wiki.language).to eq('fr')
    end
  end

  describe '#wikis' do
    it 'fetches the course wikis' do
      post "/course_wikis/#{course.id}/update", params: en_params, headers: headers
      get "/course_wikis/#{course.id}/wikis", xhr: true
      expect(response.body).to eq({ wikis: [{ language: 'en', project: 'wikipedia' }] }.to_json)
    end
  end
end
