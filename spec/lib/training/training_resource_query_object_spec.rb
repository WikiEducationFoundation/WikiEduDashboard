# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_resource_query_object"

describe TrainingResourceQueryObject do
  before(:all) do
    TrainingModule.load_all
  end

  let(:current_user) { create(:user) }

  describe '#selected_slides_and_excerpt' do
    before do
      TrainingSlide.load
    end

    # The azertyuiop string is supposed not to be present in DB
    it 'returns empty array if not found' do
      expect(query_object('azertyuiop').selected_slides_and_excerpt.size).to eq 0
    end

    # At the time of writing, there are 2 occurences of CNN in DB
    # In content text field in the TrainingSlide object
    it 'returns an array of modules' do
      expect(query_object('cnn').selected_slides_and_excerpt.size).to eq 2
    end
  end
end

def query_object(search = nil)
  described_class.new(current_user, search)
end
