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
  let(:wiki_edits) { WikiEdits.new(Wiki.find(1)) }

  let(:subject) do
    described_class.new(requested_account, creator)
  end

  it 'creates the requested accounts' do
    stub_account_creation
    allow(UserImporter).to receive(:new_from_username).and_return(user)
    expect(subject.result[:success]).not_to be_nil
    expect(user.username).to eq('Ragesock')
    expect(RequestedAccount.count).to eq(0)
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

  it 'retries account creation when the main creator account is being throttled' do
    Setting.set_special_user(:backup_account_creator, super_admin.username)
    # This will stub the request so that it fails with the appropriate
    # error message, which in turn will change the creator to the super admin
    stub_account_creation_failure_throttle
    expect(WikiEdits).to receive(:new).and_return(wiki_edits)
    expect(wiki_edits).to receive(:create_account)
      .with(creator: creator, username: anything, email: anything, reason: anything)
      .ordered.and_call_original
    expect(wiki_edits).to receive(:create_account)
      .with(creator: super_admin, username: anything, email: anything, reason: anything)
      .ordered.and_call_original
    subject
  end

  it 'only retries account creation if the request fails because of account throttling' do
    Setting.set_special_user(:backup_account_creator, super_admin.username)
    stub_account_creation_failure_unexpected
    expect(WikiEdits).to receive(:new).and_return(wiki_edits)
    expect(wiki_edits).to receive(:create_account)
      .with(creator: creator, username: anything, email: anything, reason: anything)
      .and_call_original
    expect(wiki_edits).not_to receive(:create_account)
      .with(creator: super_admin, username: anything, email: anything, reason: anything)
    subject
    expect(RequestedAccount.count).to eq(1)
  end
end
