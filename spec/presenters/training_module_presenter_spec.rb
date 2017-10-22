# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulePresenter do
  let!(:user)      { create(:user) }
  let(:lib)        { TrainingLibrary.all.first }
  let(:library_id) { lib.slug }
  let(:mod)        { TrainingModule.all.first }
  let(:module_id)  { mod.slug }
  let(:mod_params) { { library_id: library_id, module_id: module_id } }

  describe '#cta_button_text' do
    subject { described_class.new(user, mod_params).cta_button_text }
    context 'user has not started module' do
      it 'returns "Start"' do
        expect(subject).to eq('Start')
      end
    end

    context 'module is completed' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: 1.day.ago,
          last_slide_completed: mod.slides.last.slug
        )
      end
      it 'returns "View"' do
        expect(subject).to eq('View')
      end
    end

    context 'module is in progress' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: nil,
          last_slide_completed: mod.slides[-2].slug
        )
      end
      it 'returns "Continue"' do
        expect(subject).to match(/\AContinue \(\d{1,2}% Complete\)\z/)
      end
    end
  end

  describe '#cta_button_link' do
    subject { described_class.new(user, mod_params).cta_button_link }
    context 'user has not started module' do
      it 'links to first slide' do
        expect(subject.to_s).to eq("/training/#{lib.slug}/#{mod.slug}/#{mod.slides.first.slug}")
      end
    end

    context 'module is completed' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: 1.day.ago,
          last_slide_completed: mod.slides.last.slug
        )
      end
      it 'links to first slide' do
        expect(subject.to_s).to eq("/training/#{lib.slug}/#{mod.slug}/#{mod.slides.first.slug}")
      end
    end

    context 'module is in progress' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: nil,
          last_slide_completed: mod.slides[-2].slug
        )
      end
      it 'links to current slide' do
        expect(subject.to_s).to eq("/training/#{lib.slug}/#{mod.slug}/#{mod.slides[-2].slug}")
      end
    end
  end

  describe '#should_show_ttc?' do
    subject { described_class.new(user, mod_params).should_show_ttc? }
    context 'user has not started module' do
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'module is completed' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: 1.day.ago,
          last_slide_completed: mod.slides.last.slug
        )
      end
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'module is in progress' do
      before do
        TrainingModulesUsers.create(
          user_id: user.id,
          training_module_id: mod.id,
          completed_at: nil,
          last_slide_completed: mod.slides[-2].slug
        )
      end
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
