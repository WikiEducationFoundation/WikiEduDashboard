# frozen_string_literal: true

# == Schema Information
#
# Table name: requested_accounts
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  username   :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

describe RequestedAccount do
  describe 'email validation' do
    context 'when email is valid' do
      it 'saves the email' do
        account = RequestedAccount.new(username: 'foo', email: 'me@foo.com')
        account.save
        expect(account.email).to eq('me@foo.com')
      end
    end

    context 'when email is not valid' do
      it 'sets email to nil and saves' do
        account = RequestedAccount.new(username: 'foo', email: 'me@foo')
        account.save
        expect(account.email).to be_nil
      end
    end
  end
end
