# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsers do
  let(:user) { create(:user) }
  let(:training_module) { create(:training_module) }
  let(:tmu) { described_class.create(user:, training_module:) }

  describe '#store_exercise_article_title' do
    before do
      tmu.store_exercise_article_title('Octopus', 1)
      tmu.save
      tmu.reload
    end

    it 'stores the article title for the course' do
      expect(tmu.exercise_article_title(1)).to eq('Octopus')
    end

    it 'does not store it for other courses' do
      expect(tmu.exercise_article_title(2)).to be_nil
    end

    it 'marks the exercise complete for the course' do
      expect(tmu.flags[1][:marked_complete]).to eq(true)
    end
  end

  describe '#mark_completion' do
    it 'keeps the article title when unmarking the exercise' do
      tmu.store_exercise_article_title('Octopus', 1)
      tmu.mark_completion(false, 1)
      expect(tmu.flags[1]).to eq(marked_complete: false, exercise_article_title: 'Octopus')
    end
  end
end
