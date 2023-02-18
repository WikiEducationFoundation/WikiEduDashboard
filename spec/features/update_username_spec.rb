# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/controllers/update_username_controller.rb"

describe UpdateUsernameController, type: :feature, js: true do
    let(:user) { create(:user, id: 1, username: 'Old Username', global_id: 1234) }
    before { login_as user }
    
    describe 'Update Username page' do
        it 'checks if page is visited' do
           
            visit '/update_username'
            # fill_in 'username', with: 'hash'
            # click_button 'Update Username'
            expect(page).to have_content('Enter Username to update')
        end
        # it 'checks if submit button is clicked' do
        #     info = OpenStruct.new(name: 'RageSock')
        #     credentials = OpenStruct.new(token: 'foo', secret: 'bar')
        #     hash = OpenStruct.new(uid: '1234',
        #                           info:,
        #                           credentials:)
        #     visit '/update_username'
        #     fill_in('username', with: info.name)
        #     click_button 'Update Username'
        #     expect(User.find(1).id).to eq(user.id)
        #     expect(page).to have_content('My Dashboard')
        # end
    end
end