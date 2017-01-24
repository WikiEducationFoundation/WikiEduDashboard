# frozen_string_literal: true
require 'rails_helper'

describe ChatController do
  describe 'login' do
    let(:subject) { get 'login' }

    context 'when the user is signed in' do
      let(:user) { create(:user) }
      before do
        allow(controller).to receive(:current_user).and_return(user)
        stub_chat_login_success
        stub_chat_user_create_success
      end

      it 'ensures the user has a chat account' do
        expect(user.chat_password).to be_nil
        subject
        expect(user.chat_password).not_to be_nil
      end

      it 'returns an auth_token and user_id' do
        response = JSON.parse(subject.body)
        expect(response['auth_token']).to be
        expect(response['user_id']).to be
      end
    end

    context 'when the user is signed out' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'raises Unauthorized' do
        expect(subject.code).to eq('401')
      end
    end
  end
end
