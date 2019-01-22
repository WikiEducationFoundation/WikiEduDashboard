# frozen_string_literal: true

require 'rails_helper'

describe CreateRequestedAccount do
  let(:creator) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:requested_account) do
    create(
      :requested_account,
      course_id: course.id,
      username: user.username,
      email: 'email@example.com'
    )
  end

  let(:subject) do
    described_class.new(requested_account, creator)
  end

  it 'creates the requested accounts' do
    stub_account_creation
    allow(UserImporter).to receive(:new_from_username).and_return(user)
    expect(subject.result[:success]).not_to be_nil
    expect(user.username).to eq('Ragesock')
  end

  it 'destroys the requested account if the username already exist' do
    stub_account_creation_failure_userexists
    expect(subject.result[:failure]).not_to be_nil
    expect(RequestedAccount.count).to eq(0)
  end

  it 'logs an error and keeps the requested account when unexpected responses' do
    expect(Raven).to receive(:capture_exception)
    stub_account_creation_failure_unexpected
    expect(subject.result[:failure]).not_to be_nil
    expect(RequestedAccount.count).to eq(1)
  end

  it 'retries the account creation at least once if request fails' do
    ENV['account_creation_backup_creator_id'] = super_admin.id.to_s
    stub_account_creation_failure_unexpected
    expect(subject.creator).to eq(super_admin)
    expect(RequestedAccount.count).to eq(1)
  end
end
