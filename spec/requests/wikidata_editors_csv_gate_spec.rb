# frozen_string_literal: true

require 'rails_helper'

describe 'Wikidata editors CSV gate', type: :request do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:user) { create(:user) }
  let(:course) do
    create(:course, home_wiki: wikidata, slug: "foo/bar-#{SecureRandom.hex(4)}")
  end

  before do
    stub_wiki_validation
    login_as user
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(/course_wikidata_editors/).and_return(false)
  end

  context 'when there are no Wikidata user timeslices yet' do
    it 'returns the CSV without prompting for an update' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_wikidata_editors_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
    end
  end

  context 'when an existing timeslice has revisions but no stats' do
    before do
      create(:course_user_wiki_timeslice,
             course:, user:, wiki: wikidata,
             revision_count: 3, stats: {})
    end

    it 'blocks the download and asks for a full course update' do
      get '/course_wikidata_editors_csv', params: { course: course.slug }
      expect(response.body).to match(/full course update/i)
    end
  end

  context 'when all timeslices with revisions have stats' do
    before do
      create(:course_user_wiki_timeslice,
             course:, user:, wiki: wikidata,
             revision_count: 2,
             stats: { 'total revisions' => 2, 'items created' => 1 })
    end

    it 'returns the CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_wikidata_editors_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
    end
  end

  context 'when a timeslice with zero revisions has empty stats' do
    before do
      create(:course_user_wiki_timeslice,
             course:, user:, wiki: wikidata,
             revision_count: 0, stats: {})
      create(:course_user_wiki_timeslice,
             course:, user:, wiki: wikidata,
             revision_count: 5,
             stats: { 'total revisions' => 5 })
    end

    it 'is not blocked by the zero-revision timeslice' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_wikidata_editors_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
    end
  end
end
