# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/revision_score_manager"

describe RevisionScoreManager do
  let(:article) { create(:article, mw_page_id: 46721259) }
  let(:manager) { described_class.new(article) }

  describe '#scores_for' do
    before do
      # cached_score scores one revision at a time, so the stub receives [rev_id].
      allow_any_instance_of(LiftWingApi).to receive(:get_revision_data) do |_instance, rev_ids|
        rev_ids.to_h { |id| [id.to_s, { 'wp10' => id == 1_189_344_512 ? 0.5 : nil }] }
      end
    end

    it 'returns wp10 scores keyed by revision id string' do
      result = manager.scores_for([1_189_344_512, 1_189_201_347])

      expect(result).to eq('1189344512' => 0.5, '1189201347' => nil)
    end

    it 'returns an empty hash when given no revision ids' do
      expect(manager.scores_for([])).to eq({})
    end

    it 'returns an empty hash for a wiki with no articlequality model' do
      es_wiki = Wiki.find_or_initialize_by(language: 'es', project: 'wikipedia')
      es_wiki.save(validate: false) # skip the ensure_wiki_exists network call
      es_article = create(:article, mw_page_id: 999, wiki: es_wiki)

      expect(described_class.new(es_article).scores_for([1, 2])).to eq({})
    end
  end
end
