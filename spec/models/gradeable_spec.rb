# frozen_string_literal: true

# == Schema Information
#
# Table name: gradeables
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  points              :integer
#  gradeable_item_id   :integer
#  created_at          :datetime
#  updated_at          :datetime
#  gradeable_item_type :string(255)
#

require 'rails_helper'

describe Gradeable do
  describe '#save' do
    it 'ensures a points value is set' do
      described_class.new(points: 5).save
      expect(described_class.last.points).to eq(5)
      described_class.new(points: nil).save
      expect(described_class.last.points).to eq(0)
      described_class.new(points: 'text').save
      expect(described_class.last.points).to eq(0)
    end
  end
end
