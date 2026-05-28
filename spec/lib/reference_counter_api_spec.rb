# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/reference_counter_api"

describe ReferenceCounterApi do
  before { stub_wiki_validation }

  let(:en_wikipedia) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:es_wiktionary) { Wiki.get_or_create(language: 'es', project: 'wiktionary') }
  let(:commons) { Wiki.get_or_create(language: 'commons', project: 'wikimedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:deleted_rev_id) { [6115106] }
  let(:rev_ids) { [5006940, 5006942, 5006946] }

  it 'raises InvalidProjectError for wikidata' do
    expect do
      described_class.new(wikidata)
    end.to raise_error(described_class::InvalidProjectError)
  end

  it 'raises InvalidProjectError for wikimedia projects (commons, meta, etc.)' do
    expect do
      described_class.new(commons)
    end.to raise_error(described_class::InvalidProjectError)
  end

  context 'when the API returns 200 responses' do
    before do
      stub_wiki_validation
      stub_es_wiktionary_reference_counter_response
    end

    it 'returns the number of references' do
      ref_counter_api = described_class.new(es_wiktionary)
      response = ref_counter_api.get_number_of_references_from_revision_ids rev_ids + deleted_rev_id
      expect(response.dig('5006940', 'num_ref')).to eq(10)
      expect(response.dig('5006940').key?('error')).to eq(false)
      expect(response.dig('5006942', 'num_ref')).to eq(4)
      expect(response.dig('5006942').key?('error')).to eq(false)
      expect(response.dig('5006946', 'num_ref')).to eq(2)
      expect(response.dig('5006946').key?('error')).to eq(false)
      # Indicates if a revision was deleted
      expect(response.dig('6115106', 'num_ref')).to be_nil
      expect(response.dig('6115106').key?('error')).to eq(false)
      expect(response.dig('6115106', 'deleted')).to eq(true)
    end

    it 'records suppressed-content revs on the update service and does not send them to Sentry' do
      update_service = instance_double('UpdateService', record_reference_counter_403: true)
      ref_counter_api = described_class.new(es_wiktionary, update_service)

      expect(update_service).to receive(:record_reference_counter_403).once
      expect(Sentry).not_to receive(:capture_exception)

      ref_counter_api.get_number_of_references_from_revision_ids(rev_ids + deleted_rev_id)
    end
  end

  it 'logs the error once if an unexpected error raises several times' do
    reference_counter_api = described_class.new(es_wiktionary)

    stub_request(:any, /.*reference-counter.toolforge.org*/)
      .to_raise(Errno::ETIMEDOUT)

    expect(reference_counter_api).to receive(:log_error).once.with(
      Faraday::TimeoutError,
      update_service: nil,
      sentry_extra: {
         project_code: 'wiktionary',
         language_code: 'es',
         rev_ids: [5006940, 5006942, 5006946],
         error_count: 1
     }
    )
    response = reference_counter_api.get_number_of_references_from_revision_ids rev_ids
    expect(response.dig('5006942', 'num_ref')).to be_nil
    expect(response.dig('5006942', 'error')).not_to be_nil
    expect(response.dig('5006946', 'num_ref')).to be_nil
    expect(response.dig('5006946', 'error')).not_to be_nil
    expect(response.dig('5006940', 'num_ref')).to be_nil
    expect(response.dig('5006940', 'error')).not_to be_nil
  end

  # The batch endpoint returns 400 for invalid inputs (bad JSON, non-integer rev_ids,
  # too many rev_ids, invalid project/language). Per-revision errors such as
  # deleted/suppressed revisions are returned inline within a 200 response.
  context 'when the API returns non-200 responses' do
    before do
      stub_wiki_validation
      stub_400_wiki_reference_counter_response
    end

    it 'returns nil num_ref with the error body for all revisions' do
      ref_counter_api = described_class.new(en_wikipedia)
      response = ref_counter_api.get_number_of_references_from_revision_ids rev_ids
      expected_error = { 'code' => 400, 'name' => 'Bad Request',
                         'description' => "Request body must be JSON with a 'rev_ids' array." }
      expect(response.dig('5006940', 'num_ref')).to be_nil
      expect(response.dig('5006940', 'error')).to eq(expected_error)
      expect(response.dig('5006942', 'num_ref')).to be_nil
      expect(response.dig('5006942', 'error')).to eq(expected_error)
      expect(response.dig('5006946', 'num_ref')).to be_nil
      expect(response.dig('5006946', 'error')).to eq(expected_error)
    end

    it 'reports non-200 responses to Sentry' do
      update_service = instance_double('UpdateService', record_reference_counter_403: true,
                                                        update_error_stats: true,
                                                        sentry_tags: {})
      ref_counter_api = described_class.new(en_wikipedia, update_service)
      expect(Sentry).to receive(:capture_exception).once
      ref_counter_api.get_number_of_references_from_revision_ids rev_ids
    end
  end

  # Without these, a silent toolforge server blocks the worker indefinitely.
  describe 'toolforge_server connection' do
    let(:conn) { described_class.new(en_wikipedia).send(:toolforge_server) }

    it 'has a finite request timeout' do
      expect(conn.options.timeout).to eq(described_class::REQUEST_TIMEOUT)
      expect(conn.options.timeout).to be > 0
    end

    it 'has a finite open_timeout' do
      expect(conn.options.open_timeout).to eq(described_class::OPEN_TIMEOUT)
      expect(conn.options.open_timeout).to be > 0
    end
  end
end
