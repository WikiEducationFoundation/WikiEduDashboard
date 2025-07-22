# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::LocaleController, type: :request do
  describe '#update_locale' do
    let(:user) { create(:user, locale: 'fr') }
    let(:invalid_locale) { 'bad-locale' }
    let(:valid_locale) { 'es' }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    it 'returns a 422 if locale is invalid' do
      post "/update_locale/#{invalid_locale}"
      expect(response.status).to eq(422)
      expect(user.locale).to eq('fr')
    end

    it 'updates user locale and returns a 200 or 302 if locale is valid' do
      post "/update_locale/#{valid_locale}"
      expect(response.status).to eq(200).or eq(302)
      expect(user.locale).to eq('es')
    end
  end
end
