# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_api/article_content"

describe WikiApi::ArticleContent do
  let(:wiki) { Wiki.default_wiki }
  let(:subject) { described_class.new(wiki) }

  describe '#latest_revision_id' do
    it 'returns the latest revision ID for a given title' do
      response_data = {
        'pages' => {
          '12345' => {
            'revisions' => [{ 'revid' => 999 }]
          }
        }
      }
      response = double('response', data: response_data, status: 200)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      result = subject.latest_revision_id('Test_Article')
      expect(result).to eq(999)
    end

    it 'returns nil when no revisions exist' do
      response_data = {
        'pages' => {
          '-1' => { 'missing' => '' }
        }
      }
      response = double('response', data: response_data, status: 200)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      result = subject.latest_revision_id('Nonexistent_Page')
      expect(result).to be_nil
    end
  end

  describe '#parent_revision_id' do
    it 'returns the parent revision ID' do
      response_data = {
        'pages' => {
          '100' => {
            'revisions' => [{ 'revid' => 200, 'parentid' => 199 }]
          }
        }
      }
      response = double('response', data: response_data, status: 200)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      result = subject.parent_revision_id(200)
      expect(result).to eq(199)
    end

    it 'returns nil for a missing/deleted revision' do
      response_data = { 'badrevids' => { '999' => { 'revid' => 999 } } }
      response = double('response', data: response_data, status: 200)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      expect(Sentry).to receive(:capture_message)
        .with('WikiApi::ArticleContent: revision 999 missing or deleted')
      result = subject.parent_revision_id(999)
      expect(result).to be_nil
    end
  end

  describe '#parent_revision_ids' do
    it 'returns a hash of rev_id => parent_id for a batch' do
      response_data = {
        'pages' => {
          '1' => {
            'revisions' => [
              { 'revid' => 100, 'parentid' => 99 },
              { 'revid' => 101, 'parentid' => 100 }
            ]
          }
        }
      }
      response = double('response', data: response_data)
      allow(response).to receive(:present?).and_return(true)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      result = subject.parent_revision_ids([100, 101])
      expect(result).to eq({ 100 => '99', 101 => '100' })
    end

    it 'skips revisions with parentid of 0' do
      response_data = {
        'pages' => {
          '1' => {
            'revisions' => [
              { 'revid' => 100, 'parentid' => 0 }
            ]
          }
        }
      }
      response = double('response', data: response_data)
      allow(response).to receive(:present?).and_return(true)
      allow_any_instance_of(WikiApi).to receive(:query).and_return(response)

      result = subject.parent_revision_ids([100])
      expect(result).to eq({})
    end

    it 'returns empty hash for blank input' do
      result = subject.parent_revision_ids([])
      expect(result).to eq({})
    end
  end

  describe '#revision_html' do
    it 'returns html, title, and page_id' do
      response_data = {
        'text' => { '*' => '<p>Hello world</p>' },
        'title' => 'Test Article',
        'pageid' => 42
      }
      response = double('response', data: response_data)
      api_client = double('api_client')
      allow_any_instance_of(WikiApi).to receive(:api_client).and_return(api_client)
      allow(api_client).to receive(:send).with(:action, 'parse', { oldid: 123 })
                                         .and_return(response)

      result = subject.revision_html(123)
      expect(result[:html]).to eq('<p>Hello world</p>')
      expect(result[:title]).to eq('Test Article')
      expect(result[:page_id]).to eq(42)
    end
  end

  describe '#parse_wikitext' do
    it 'returns parsed HTML from wikitext' do
      response_data = { 'text' => { '*' => '<p>Parsed content</p>' } }
      response = double('response', data: response_data)
      api_client = double('api_client')
      allow_any_instance_of(WikiApi).to receive(:api_client).and_return(api_client)
      allow(api_client).to receive(:send)
        .with(:action, 'parse', { text: '== Heading ==', contentmodel: 'wikitext' })
        .and_return(response)

      result = subject.parse_wikitext('== Heading ==')
      expect(result).to eq('<p>Parsed content</p>')
    end
  end

  describe '#revision_diff' do
    it 'returns diff_html, title, and page_id' do
      response_data = {
        '*' => '<table>diff content</table>',
        'totitle' => 'Test Article',
        'toid' => 42
      }
      response = double('response', data: response_data)
      api_client = double('api_client')
      allow_any_instance_of(WikiApi).to receive(:api_client).and_return(api_client)
      allow(api_client).to receive(:send)
        .with(:action, 'compare', { torev: 200, fromrev: 100, difftype: 'table' })
        .and_return(response)

      result = subject.revision_diff(100, 200)
      expect(result[:diff_html]).to eq('<table>diff content</table>')
      expect(result[:title]).to eq('Test Article')
      expect(result[:page_id]).to eq(42)
    end

    it 'returns nil when the revision content is missing' do
      api_client = double('api_client')
      allow_any_instance_of(WikiApi).to receive(:api_client).and_return(api_client)
      err_response = double('response', data: { 'code' => 'missingcontent',
                                                 'info' => 'Missing content for revision ID 200.' })
      allow(api_client).to receive(:send)
        .with(:action, 'compare', { torev: 200, fromrev: 100, difftype: 'table' })
        .and_raise(MediawikiApi::ApiError.new(err_response))

      expect(Sentry).to receive(:capture_message)
        .with(/revision content missing for diff 100 -> 200/)
      expect(subject.revision_diff(100, 200)).to be_nil
    end

    it 're-raises ApiErrors with other codes' do
      api_client = double('api_client')
      allow_any_instance_of(WikiApi).to receive(:api_client).and_return(api_client)
      err_response = double('response', data: { 'code' => 'somethingelse', 'info' => 'oops' })
      allow(api_client).to receive(:send)
        .with(:action, 'compare', { torev: 200, fromrev: 100, difftype: 'table' })
        .and_raise(MediawikiApi::ApiError.new(err_response))

      expect { subject.revision_diff(100, 200) }.to raise_error(MediawikiApi::ApiError)
    end
  end

  describe '#revision_history' do
    it 'returns all revisions handling continuation' do
      first_response_data = {
        'pages' => {
          '42' => {
            'revisions' => [
              { 'revid' => 300, 'user' => 'Alice' },
              { 'revid' => 299, 'user' => 'Bob' }
            ]
          }
        }
      }
      first_response = double('response', data: first_response_data)
      allow(first_response).to receive(:[]).with('continue')
        .and_return({ 'rvcontinue' => '20240101|298' })

      second_response_data = {
        'pages' => {
          '42' => {
            'revisions' => [
              { 'revid' => 298, 'user' => 'Charlie' }
            ]
          }
        }
      }
      second_response = double('response', data: second_response_data)
      allow(second_response).to receive(:[]).with('continue').and_return(nil)

      allow_any_instance_of(WikiApi).to receive(:query)
        .and_return(first_response, second_response)

      start_date = Time.zone.parse('2025-01-01')
      end_date = Time.zone.parse('2024-01-01')
      result = subject.revision_history(42, start_date: start_date, end_date: end_date)

      expect(result.length).to eq(3)
      expect(result.map { |r| r['user'] }).to eq(['Alice', 'Bob', 'Charlie'])
    end

    it 'returns empty array when API fails' do
      allow_any_instance_of(WikiApi).to receive(:query).and_return(nil)

      start_date = Time.zone.parse('2025-01-01')
      end_date = Time.zone.parse('2024-01-01')
      result = subject.revision_history(42, start_date: start_date, end_date: end_date)

      expect(result).to eq([])
    end
  end
end
