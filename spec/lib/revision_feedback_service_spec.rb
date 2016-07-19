require 'rails_helper'
require "#{Rails.root}/lib/revision_feedback_service"

describe RevisionFeedbackService do
  describe '#feedback' do
    let(:subject) { described_class.new(revision).feedback }

    context 'when the revision has no feature data' do
      let(:revision) { create(:revision) }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when the revision has feature data that prompts feedback' do
      let(:revision) { create(:revision, features: features) }
      let(:features) do
        { 'feature.enwiki.revision.cite_templates' => 6,
          'feature.wikitext.revision.ref_tags' => 0,
          'feature.wikitext.revision.content_chars' => 9001,
          'feature.wikitext.revision.headings_by_level(2)' => 0,
          'feature.wikitext.revision.headings_by_level(3)' => 0 }
      end

      it 'returns an array of relevant feedback' do
        expect(subject.length).to eq(2)
      end
    end

    context 'when the revision has feature data that does not prompt feedback' do
      let(:revision) { create(:revision, features: features) }
      let(:features) do
        { 'feature.enwiki.revision.cite_templates' => 6,
          'feature.wikitext.revision.ref_tags' => 10,
          'feature.wikitext.revision.content_chars' => 9001,
          'feature.wikitext.revision.headings_by_level(2)' => 4,
          'feature.wikitext.revision.headings_by_level(3)' => 1 }
      end

      it 'returns an array with a no-feedback message' do
        expect(subject.length).to eq(1)
        expect(subject[0]).to be =~ /no suggestions available/
      end
    end
  end
end
