# frozen_string_literal: true

require 'rails_helper'

describe GetRevisionPlaintext do
  let(:wiki) { double('Wiki') }

  def stub_revision_html(html)
    response_data = {
      'text' => { '*' => html },
      'title' => 'Test Article',
      'pageid' => 123
    }
    response = double('response', data: response_data)
    api_client = double('api_client')
    wiki_api = double('WikiApi')
    allow(WikiApi).to receive(:new).and_return(wiki_api)
    allow(wiki_api).to receive(:api_client).and_return(api_client)
    allow(api_client).to receive(:action).with('parse', anything).and_return(response)
  end

  describe '#plain_text' do
    it 'excludes figure-based images and captions' do
      stub_revision_html(<<~HTML)
        <p>Start text.</p>
        <figure typeof="mw:File/Thumb">
          <a href="/wiki/File:Example.jpg"><img src="example.jpg" /></a>
          <figcaption>Example caption</figcaption>
        </figure>
        <p>End text.</p>
      HTML
      service = described_class.new(12345, wiki, diff_mode: false)
      expect(service.plain_text).to include('Start text.')
      expect(service.plain_text).to include('End text.')
      expect(service.plain_text).not_to include('Example caption')
    end

    it 'excludes inline images' do
      stub_revision_html(<<~HTML)
        <p>Text before <a href="/wiki/File:Icon.png" class="image"><img src="icon.png" /></a> text after.</p>
      HTML
      service = described_class.new(12345, wiki, diff_mode: false)
      expect(service.plain_text).to include('Text before')
      expect(service.plain_text).to include('text after')
    end

    it 'preserves normal prose' do
      stub_revision_html('<p>Just some normal text.</p>')
      service = described_class.new(12345, wiki, diff_mode: false)
      expect(service.plain_text).to eq('Just some normal text.')
    end
  end
end
