# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/reference_counter_api"

describe ReferenceCounterApi do
  before { stub_wiki_validation }

  let(:en_wikipedia) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:es_wiktionary) { Wiki.get_or_create(language: 'es', project: 'wiktionary') }
  let(:not_supported) { Wiki.get_or_create(language: 'incubator', project: 'wikimedia') }
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:deleted_rev_ids) { [708326238] }
  let(:rev_ids) { [5006940, 5006942, 5006946] }

  it 'raises InvalidProjectError if using wikidata project' do
    expect do
      described_class.new(wikidata)
    end.to raise_error(described_class::InvalidProjectError)
  end

  context 'returns the number of references' do
    before do
      stub_wiki_validation
      stub_es_wiktionary_reference_counter_response
    end

    # Get revision data for valid rev ids for Wikidata
    it 'if response is 200 OK', vcr: true do
      ref_counter_api = described_class.new(es_wiktionary)
      response = ref_counter_api.get_number_of_references_from_revision_ids rev_ids
      expect(response.dig('5006940', 'num_ref')).to eq(10)
      expect(response.dig('5006940').key?('error')).to eq(false)
      expect(response.dig('5006942', 'num_ref')).to eq(4)
      expect(response.dig('5006942').key?('error')).to eq(false)
      expect(response.dig('5006946', 'num_ref')).to eq(2)
      expect(response.dig('5006946').key?('error')).to eq(false)
    end
  end

  context 'fails silently' do
    before do
      stub_wiki_validation
    end

    it 'if response is 400 bad request' do
      stub_400_wiki_reference_counter_response
      ref_counter_api = described_class.new(not_supported)
      response = ref_counter_api.get_number_of_references_from_revision_ids rev_ids
      expect(response.dig('5006940', 'num_ref')).to be_nil
      expect(response.dig('5006940').key?('error')).to eq(false)
      expect(response.dig('5006942', 'num_ref')).to be_nil
      expect(response.dig('5006942').key?('error')).to eq(false)
      expect(response.dig('5006946', 'num_ref')).to be_nil
      expect(response.dig('5006946').key?('error')).to eq(false)
    end

    it 'if response is 403 forbidden' do
      stub_403_wiki_reference_counter_response
      ref_counter_api = described_class.new(not_supported)
      response = ref_counter_api.get_number_of_references_from_revision_ids rev_ids
      expect(response.dig('5006940', 'num_ref')).to be_nil
      expect(response.dig('5006940').key?('error')).to eq(false)
      expect(response.dig('5006942', 'num_ref')).to be_nil
      expect(response.dig('5006942').key?('error')).to eq(false)
      expect(response.dig('5006946', 'num_ref')).to be_nil
      expect(response.dig('5006946').key?('error')).to eq(false)
    end
  end

  # it 'logs the message if response is not 200 OK', vcr: true do
  #   ref_counter_api = described_class.new(en_wikipedia)
  #   expect(Sentry).to receive(:capture_message).with(
  #     'Non-200 response hitting references counter API',
  #     level: 'warning',
  #     extra: {
  #       project_code: 'wikipedia',
  #       language_code: 'en',
  #       rev_id: 708326238,
  #       status_code: 403,
  #       content: {
  #           'description' =>
  #           "mwapi error: permissiondenied - You don't have permission to view deleted " \
  #           'text or changes between deleted revisions.'
  #       }
  #     }
  #   )
  #   response = ref_counter_api.get_number_of_references_from_revision_ids deleted_rev_ids
  #   expect(response.dig('708326238')).to eq({ 'num_ref' => nil })
  # end

  it 'logs the error once if an unexpected error raises several times', vcr: true do
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
         error_count: 3
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
end
