# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/string_utils"

describe StringUtils do
  describe '#excerpt' do
    it 'pads only at the end when text not found' do
      expect(described_class.excerpt('One two three', 'four', 20)).to eq 'One two three...'
    end

    it 'pads left when found text at the beginning' do
      expect(described_class.excerpt('One two three four', 'One', 20))
        .to eq '...<mark>One</mark> two...'
    end
  end
end
