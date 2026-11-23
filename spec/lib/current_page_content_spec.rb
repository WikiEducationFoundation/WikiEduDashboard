# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/current_page_content"

describe CurrentPageContent do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  it 'returns the current wikitext of the page' do
    stub_current_page_content('Talk page text')
    expect(described_class.fetch(wiki, 'Talk:Selfie')).to eq('Talk page text')
  end

  it 'returns an empty string for a page that does not exist' do
    stub_current_page_content('')
    expect(described_class.fetch(wiki, 'Talk:Missing')).to eq('')
  end

  it 'raises PageFetchError when the wiki cannot be read' do
    stub_request(:get, %r{en\.wikipedia\.org/w/api\.php}).to_return(status: 503, body: '')
    expect { described_class.fetch(wiki, 'Talk:Selfie') }
      .to raise_error(WikiApi::PageFetchError)
  end

  it 'reads through the action API, not the CDN-cached action=raw' do
    stub_current_page_content('Talk page text')
    described_class.fetch(wiki, 'Talk:Selfie')
    expect(a_request(:get, /action=raw/)).not_to have_been_made
  end
end
