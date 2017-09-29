# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/chat/rocket_chat"

describe RocketChat do
  let(:user) { nil }
  let(:course) { nil }
  let(:subject) { RocketChat.new(user: user, course: course) }

  describe '#login_credentials' do
    let(:user) { create(:user, chat_password: chat_password, chat_id: chat_id) }

    context 'when the user already has a Rocket.Chat account' do
      let(:chat_id) { 'chatIdForUser' }
      let(:chat_password) { 'random_password' }
      before { stub_chat_login_success }

      it 'returns an authToken and userId' do
        expect(subject.login_credentials).to eq('authToken' => 'fakeAuthToken',
                                                'userId' => 'chatIdForUser')
      end

      it 'does not change the chat id or password' do
        subject.login_credentials
        expect(user.chat_id).to eq(chat_id)
        expect(user.chat_password).to eq(chat_password)
      end
    end

    context 'when the user does not have a chat account' do
      let(:chat_password) { nil }
      let(:chat_id) { nil }

      before do
        stub_chat_login_success
        stub_chat_user_create_success
      end

      it 'creates an account, then returns an authToken and userId' do
        expect(subject.login_credentials).to eq('authToken' => 'fakeAuthToken',
                                                'userId' => 'chatIdForUser')
      end

      it 'saves the user\'s chat id and password' do
        expect(user.chat_password).to be_nil
        expect(user.chat_id).to be_nil

        subject.login_credentials
        expect(user.chat_password).not_to be_nil
        expect(user.chat_id).to eq('userId') # value from stub_chat_user_create_success
      end
    end
  end

  describe '#create_channel_for_course' do
    before do
      stub_chat_login_success
      stub_chat_channel_create_success
    end

    context 'when the enable_chat flag is set for the course' do
      let(:course) { create(:course, flags: { enable_chat: true }) }

      it 'saves the course\'s room ID' do
        expect(course.chatroom_id).to be_nil
        subject.create_channel_for_course
        expect(course.chatroom_id).not_to be_nil
      end
    end

    context 'when the enable_chat flag is not set for the course' do
      let(:course) { create(:course, flags: {}) }

      it 'does nothing' do
        expect(course.chatroom_id).to be_nil
        subject.create_channel_for_course
        expect(course.chatroom_id).to be_nil
      end
    end

    context 'when the Rocket.Chat API returns an error' do
      let(:course) { create(:course, flags: { enable_chat: true }) }
      before { stub_chat_error }
      it 'raises RocketChatAPIError' do
        expect { subject.create_channel_for_course }.to raise_error(RocketChat::RocketChatAPIError)
      end
    end
  end
end
