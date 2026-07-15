# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsers do
  let(:user) { create(:user) }

  describe '#eligible_for_completion?' do
    let(:wiki) { Wiki.find_by(language: 'en', project: 'wikipedia') }

    context 'when the module has no sandbox_location and no article_title_input' do
      let(:training_module) { create(:training_module) }
      let(:tmu) do
        TrainingModulesUsers.create(user:, training_module:)
      end

      it 'returns true without any API check' do
        expect(tmu.eligible_for_completion?(wiki)).to be true
      end
    end

    context 'when the module has sandbox_location' do
      let(:training_module) do
        create(:training_module, settings: { 'sandbox_location' => 'Evaluate_an_Article' })
      end
      let(:tmu) do
        TrainingModulesUsers.create(user:, training_module:)
      end

      it 'returns true when the sandbox page has content' do
        allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('some content')
        expect(tmu.eligible_for_completion?(wiki)).to be true
      end

      it 'returns false when the sandbox page is empty' do
        allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('')
        expect(tmu.eligible_for_completion?(wiki)).to be false
      end
    end

    context 'when the module has article_title_input' do
      let(:training_module) do
        create(:training_module, settings: { 'article_title_input' => true }, kind: 1)
      end
      let(:tmu) do
        TrainingModulesUsers.create(user:, training_module:)
      end

      it 'returns false when no article title has been saved' do
        expect(tmu.eligible_for_completion?(wiki)).to be false
      end

      it 'returns true when an article title has been saved' do
        tmu.store_exercise_article_title('Selfie')
        tmu.save
        expect(tmu.eligible_for_completion?(wiki)).to be true
      end

      it 'does not make a WikiApi call' do
        tmu.store_exercise_article_title('Selfie')
        tmu.save
        expect(WikiApi).not_to receive(:new)
        tmu.eligible_for_completion?(wiki)
      end
    end
  end

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
