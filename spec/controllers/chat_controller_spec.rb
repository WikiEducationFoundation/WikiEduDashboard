# frozen_string_literal: true

require 'rails_helper'

describe ChatController, type: :request do
  describe 'login' do
    let(:subject) { get '/chat/login' }

    context 'when the user is signed in' do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        stub_chat_login_success
        stub_chat_user_create_success
      end

      it 'ensures the user has a chat account' do
        expect(user.chat_password).to be_nil
        subject
        expect(user.chat_password).not_to be_nil
      end

      it 'returns an auth_token and user_id' do
        subject
        response_data = Oj.load(response.body)
        expect(response_data['auth_token']).not_to be_nil
        expect(response_data['user_id']).not_to be_nil
      end

      it 'raises an error if chat is not enabled' do
        allow(Features).to receive(:enable_chat?).and_return(false)
        subject
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is signed out' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it 'raises Unauthorized' do
        subject
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'enable_for_course' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }

    before do
      create(:courses_user, user_id: user.id, course_id: course.id)
    end

    context 'when the user is an admin' do
      let(:admin) { create(:admin) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        stub_chat_login_success
        stub_chat_user_create_success
        stub_chat_channel_create_success
        stub_add_user_to_channel_success
      end

      it 'sets the chat flag and creates accounts for users' do
        put "/chat/enable_for_course/#{course.id}", params: { course_id: course.id }
        expect(course.reload.flags[:enable_chat]).to eq(true)
        expect(user.reload.chat_id).not_to be_nil
      end
    end

    context 'when the user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'raises Unauthorized' do
        put "/chat/enable_for_course/#{course.id}", params: { course_id: course.id }
        expect(response.status).to eq(401)
      end
    end
  end
end
