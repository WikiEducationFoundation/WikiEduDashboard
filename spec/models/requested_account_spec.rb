# frozen_string_literal: true
# == Schema Information
#
# Table name: requested_accounts
#
#  id         :bigint           not null, primary key
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
        account = described_class.new(username: 'foo', email: 'me@foo.com')
        account.save
        expect(account.email).to eq('me@foo.com')
      end
    end

    context 'when email is not valid' do
      it 'does not save the record and adds an error' do
        account = described_class.new(username: 'foo', email: 'me@foo')
        account.save
        expect(account.errors).not_to be_empty
        expect(account.persisted?).to eq(false)
      end
    end
  end
end
