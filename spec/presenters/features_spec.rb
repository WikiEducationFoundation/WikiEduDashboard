# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/features'

describe Features do
  describe '.wiki_ed?' do
    context 'when wiki_education is true' do
      before do
        allow(ENV).to receive(:[]).with('wiki_education').and_return('true')
      end

      it 'returns true' do
        expect(described_class.wiki_ed?).to eq(true)
      end
    end
  end

  # Legacy (LTI 1.1) launches are opt-in per deployment, on top of the Canvas
  # integration flag: off unless the env var says exactly 'true'.
  describe '.lti_legacy_launches?' do
    it 'is off by default' do
      allow(ENV).to receive(:[]).with('lti_legacy_launches_enabled').and_return(nil)
      expect(described_class.lti_legacy_launches?).to eq(false)
    end

    it 'is on when enabled explicitly' do
      allow(ENV).to receive(:[]).with('lti_legacy_launches_enabled').and_return('true')
      expect(described_class.lti_legacy_launches?).to eq(true)
    end
  end
end
