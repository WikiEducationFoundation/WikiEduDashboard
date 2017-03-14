# frozen_string_literal: true
require 'rails_helper'

describe Editathon do
  let(:subject) { create(:editathon) }
  describe '#assignment_edits_enabled?' do
    it 'returns false' do
      expect(subject.assignment_edits_enabled?).to eq(false)
    end
  end
end
