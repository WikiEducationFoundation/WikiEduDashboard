require 'rails_helper'
require "#{Rails.root}/lib/tag_manager"

describe TagManager do
  describe '#initial_tags' do
    let(:course) { create(:course) }
    let(:creator) { create(:user) }
    let(:subject) { course.tags.first.tag }

    it 'adds a returning_instructor tag if the creator is a returning instructor' do
      expect(creator).to receive(:returning_instructor?).and_return(true)
      TagManager.new(course).initial_tags(creator: creator)
      expect(subject).to eq('returning_instructor')
    end

    it 'adds a first_time_instructor tag if the creator is not a returning instructor' do
      expect(creator).to receive(:returning_instructor?).and_return(false)
      TagManager.new(course).initial_tags(creator: creator)
      expect(subject).to eq('first_time_instructor')
    end
  end
end
