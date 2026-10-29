# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/source_kind"

describe ClaimLibrary::SourceKind do
  {
    'https://pmc.ncbi.nlm.nih.gov/articles/PMC10327345/' => 'journal',
    'https://doi.org/10.1136/bmjgh-2018-000986' => 'journal',
    'https://www.theguardian.com/commentisfree/2012/jun/05/india-surrogates' => 'opinion',
    'http://blog.indiansurrogacylaw.com' => 'blog',
    'https://fightyourinfertility.com/5537/16-things' => 'web',
    'http://mha.nic.in/uniquepage.asp?Id_Pk=553' => 'government',
    'https://www.scconline.com/' => 'database_home',
    'https://en.wikipedia.org/wiki/Surrogacy' => 'wikipedia',
    nil => 'offline'
  }.each do |url, kind|
    it "calls #{url.inspect} #{kind}" do
      expect(described_class.of(url)).to eq(kind)
    end
  end

  it 'does not choke on a malformed URL' do
    expect(described_class.of('http://exa mple.com/x')).to eq('web')
  end
end
