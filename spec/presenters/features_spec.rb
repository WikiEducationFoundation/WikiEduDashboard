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
end
