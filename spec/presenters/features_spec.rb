# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/features'

describe Features do
  describe '.wiki_ed?' do
    context 'when the url is dashboard-testing.wikiedu.org' do
      before do
        allow(ENV).to receive(:[]).with('wiki_education').and_return('true')
      end
      it 'returns true' do
        expect(Features.wiki_ed?).to eq(true)
      end
    end

    context 'when the url is outreachdashboard.wmflabs.org' do
      before do
        allow(ENV).to receive(:[]).with('wiki_education').and_return('false')
      end
      it 'returns false' do
        expect(Features.wiki_ed?).to eq(false)
      end
    end
  end
end
