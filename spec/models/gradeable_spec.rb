# frozen_string_literal: true
require 'rails_helper'

describe Gradeable do
  describe '#save' do
    it 'ensures a points value is set' do
      Gradeable.new(points: 5).save
      expect(Gradeable.last.points).to eq(5)
      Gradeable.new(points: nil).save
      expect(Gradeable.last.points).to eq(0)
      Gradeable.new(points: 'text').save
      expect(Gradeable.last.points).to eq(0)
    end
  end
end
