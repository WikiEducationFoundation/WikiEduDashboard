# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_resource_query_object"

describe TrainingResourceQueryObject do
  before(:all) do
    TrainingModule.load_all
  end

  let(:current_user) { create(:user) }

  describe '::find_libraries' do
    before do
      TrainingSlide.load
    end

    # The azertyuiop string is supposed not to be present in DB
    it 'returns empty array if not found' do
      expect(described_class.find_libraries('azertyuiop', current_user)[1].size).to eq 0
    end

    # At the time of writing, there are 2 occurences of CNN in DB
    # In content text field in the TrainingSlide object
    it 'returns an array of modules' do
      expect(described_class.find_libraries('cnn', current_user)[1].size).to eq 2
    end
  end
end
