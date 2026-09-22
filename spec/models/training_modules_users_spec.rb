# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsers do
  let(:user) { create(:user) }

  describe '#store_exercise_article_title and #exercise_article_title' do
    let(:training_module) { create(:training_module) }
    let(:tmu) { TrainingModulesUsers.create(user:, training_module:) }

    it 'stores and retrieves the article title from flags' do
      tmu.store_exercise_article_title('Octopus')
      tmu.save
      expect(tmu.reload.exercise_article_title).to eq('Octopus')
    end
  end
end
