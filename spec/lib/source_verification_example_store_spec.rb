# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/source_verification_example_store"

describe SourceVerificationExampleStore do
  let(:store_path) { Rails.root.join('tmp/test_source_verification_examples.json') }

  let(:example) do
    {
      claim: 'The lighthouse was automated at the end of 1985.',
      citations: [{ ref_id: 'cite_note-1', citation_text: '"Lighthouse". Example News.',
                    source_type: 'web', url: 'https://example.com/lighthouse',
                    urls: ['https://example.com/lighthouse'], web_accessible: true }],
      article_title: 'Test Article',
      mw_page_id: 42,
      mw_rev_id: 500
    }
  end

  before do
    stub_const('SourceVerificationExampleStore::PATH', store_path)
    FileUtils.rm_f(store_path)
  end

  after { FileUtils.rm_f(store_path) }

  describe '.add' do
    it 'persists examples with stable ids' do
      added = described_class.add([example])

      expect(added).to eq(1)
      stored = described_class.all.first
      expect(stored[:claim]).to eq(example[:claim])
      expect(stored[:id]).to be_a(String)
      expect(stored[:id].length).to eq(SourceVerificationExampleStore::ID_LENGTH)
    end

    it 'does not duplicate an example added twice' do
      described_class.add([example])
      added_again = described_class.add([example])

      expect(added_again).to eq(0)
      expect(described_class.count).to eq(1)
    end

    it 'appends new examples to the existing collection' do
      described_class.add([example])
      other = example.merge(claim: 'The harbor was dredged to a depth of twelve meters.')
      described_class.add([other])

      expect(described_class.count).to eq(2)
    end
  end

  describe '.all' do
    it 'returns symbolized example hashes after a JSON round trip' do
      described_class.add([example])

      stored = described_class.all.first
      expect(stored[:citations].first[:url]).to eq('https://example.com/lighthouse')
    end

    it 'returns an empty array when no file exists' do
      expect(described_class.all).to eq([])
    end
  end

  describe '.find' do
    it 'returns the example with the given id' do
      described_class.add([example])
      id = described_class.all.first[:id]

      expect(described_class.find(id)[:claim]).to eq(example[:claim])
    end

    it 'returns nil for an unknown id' do
      expect(described_class.find('nope')).to be_nil
    end
  end

  describe '.random' do
    it 'returns a stored example' do
      described_class.add([example])

      expect(described_class.random[:claim]).to eq(example[:claim])
    end
  end
end
