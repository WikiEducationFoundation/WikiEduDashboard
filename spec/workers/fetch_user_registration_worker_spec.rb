# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/fetch_user_registration_worker"

describe FetchUserRegistrationWorker do
  let(:user) { create(:user, registered_at: nil) }

  it 'calls UserImporter.update_users with the user' do
    expect(UserImporter).to receive(:update_users).with([user])
    described_class.new.perform(user.id)
  end

  it 'does nothing when the user does not exist' do
    expect(UserImporter).not_to receive(:update_users)
    described_class.new.perform(0)
  end
end
