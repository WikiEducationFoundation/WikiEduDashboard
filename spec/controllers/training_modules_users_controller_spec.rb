# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsersController do
  describe '#create_or_update' do
    let(:user)  { create(:user) }
    let(:t_mod) { TrainingModule.all.first }
    let(:slide) { t_mod.slides.first }
    let(:post_params) do
      { module_id: t_mod.slug,
        slide_id: slide.slug,
        user_id: user.id }
    end

    before { allow(controller).to receive(:current_user).and_return(user) }

    it 'sets a slide complete' do
      post :create_or_update, params: post_params, format: :json
      expect(TrainingModulesUsers.last.last_slide_completed).to eq(slide.slug)
    end

    context 'first slide' do
      it 'does not set the module complete' do
        post :create_or_update, params: post_params, format: :json
        expect(TrainingModulesUsers.last.completed_at).to be_nil
      end
    end

    context 'last slide' do
      let(:slide) { t_mod.slides.last }
      it 'does set the module complete' do
        post :create_or_update, params: post_params, format: :json
        expect(TrainingModulesUsers.last.completed_at)
          .to be_between(1.minute.ago, 1.minute.from_now)
      end
    end
    context 'nonexistent slide' do
      let(:nonexistent_slide_params) do
        { module_id: t_mod.slug,
          slide_id: 'not-a-real-slide',
          user_id: user.id }
      end

      it 'renders a response' do
        post :create_or_update, params: nonexistent_slide_params, format: :json
        expect(response.status).to eq(200)
      end
    end
  end
end
