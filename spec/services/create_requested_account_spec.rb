# frozen_string_literal: true

require 'rails_helper'

describe CreateRequestedAccount do
  let(:creator) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:course) { create(:course, home_wiki:) }
  let(:home_wiki) { Wiki.get_or_create(language: 'fr', project: 'wikipedia') }
  let(:en_wiki) { Wiki.find 1 }
  let(:user) { create(:user) }
  let(:requested_account) do
    create(
      :requested_account,
      course:,
      username: user.username,
      email: 'email@example.com'
    )
  end
  let(:en_wiki_edits) { WikiEdits.new(en_wiki) }
  let(:homewiki_wiki_edits) { WikiEdits.new(home_wiki) }

  let(:subject) do
    described_class.new(requested_account, creator)
  end

  before do
    stub_wiki_validation
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('edit_fr.wikipedia.org').and_return('true')
  end

  it 'creates the requested accounts' do
    stub_account_creation(wiki: home_wiki)
    allow(UserImporter).to receive(:new_from_username).and_return(user)
    expect(subject.result[:success]).not_to be_nil
    expect(subject.result[:result_description])
      .to include(I18n.t('users.requested_account_status.success_message',
                         result_description: ''))
    expect(user.username).to eq('Ragesock')
    expect(RequestedAccount.count).to eq(0)
  end

  it 'destroys the requested account if the username already exist' do
    stub_account_creation_failure_userexists(wiki: home_wiki)
    expect(subject.result[:failure]).not_to be_nil
    expect(subject.result[:result_description])
      .to include(I18n.t('users.requested_account_status.failure_message',
                         result_description: ''))
    expect(RequestedAccount.count).to eq(0)
  end

  it 'explains that the username is already taken' do
    stub_account_creation_failure_userexists(wiki: home_wiki)
    expect(subject.result[:failure])
      .to eq(I18n.t('users.requested_account_status.user_exists',
                    username: user.username, email: 'email@example.com',
                    wiki: 'fr.wikipedia.org'))
  end

  it 'logs an error and keeps the requested account when unexpected responses' do
    expect(Sentry).to receive(:capture_exception)
    stub_account_creation_failure_unexpected(wiki: home_wiki)
    expect(subject.result[:failure]).not_to be_nil
    expect(subject.result[:result_description])
      .to include(I18n.t('users.requested_account_status.failure_message',
                         result_description: ''))
    expect(RequestedAccount.count).to eq(1)
  end

  it 'does not show the raw API response for an unexpected response' do
    allow(Sentry).to receive(:capture_exception)
    stub_account_creation_failure_unexpected(wiki: home_wiki)
    expect(subject.result[:failure])
      .to eq(I18n.t('users.requested_account_status.unexpected',
                    username: user.username, email: 'email@example.com',
                    wiki: 'fr.wikipedia.org'))
    expect(subject.result[:result_description]).not_to include('createaccount')
  end

  it 'sends the raw API response to Sentry for an unexpected response' do
    stub_account_creation_failure_unexpected(wiki: home_wiki)
    expect(Sentry).to receive(:capture_exception)
      .with(an_instance_of(described_class::AccountCreationError),
            extra: { response: { 'createaccount' => { 'username' => 'Ragetest 99' } } })
    subject
  end

  it 'passes on the reason when the wiki rejects the request with a message' do
    allow(Sentry).to receive(:capture_exception)
    stub_account_creation_failure_rejected(wiki: home_wiki)
    expect(subject.result[:failure])
      .to eq(I18n.t('users.requested_account_status.rejected',
                    username: user.username, email: 'email@example.com',
                    wiki: 'fr.wikipedia.org',
                    message: 'The email address cannot be accepted.'))
    expect(RequestedAccount.count).to eq(1)
  end

  it 'explains a throttle when the backup account is throttled too' do
    SpecialUsers.set_user(:backup_account_creator, super_admin.username)
    allow(Sentry).to receive(:capture_exception)
    stub_account_creation_failure_throttle(wiki: home_wiki)
    stub_account_creation_token_request(wiki: en_wiki)
    expect(subject.result[:failure])
      .to eq(I18n.t('users.requested_account_status.throttled',
                    username: user.username, email: 'email@example.com',
                    wiki: 'en.wikipedia.org'))
    expect(RequestedAccount.count).to eq(1)
  end

  it 'explains a CAPTCHA when the backup account gets one too' do
    SpecialUsers.set_user(:backup_account_creator, super_admin.username)
    allow(Sentry).to receive(:capture_exception)
    stub_account_creation_failure_captcha(wiki: home_wiki)
    stub_account_creation_token_request(wiki: en_wiki)
    expect(subject.result[:failure])
      .to eq(I18n.t('users.requested_account_status.captcha_required',
                    username: user.username, email: 'email@example.com',
                    wiki: 'en.wikipedia.org'))
    expect(RequestedAccount.count).to eq(1)
  end

  it 'retries account creation when the main creator account is being throttled' do
    SpecialUsers.set_user(:backup_account_creator, super_admin.username)
    # This will stub the request so that it fails with the appropriate
    # error message, which in turn will change the creator to the super admin
    stub_account_creation_failure_throttle(wiki: home_wiki)
    stub_account_creation(wiki: en_wiki)
    expect(WikiEdits).to receive(:new).twice.and_call_original
    expect(WikiEdits).to receive(:new).with(home_wiki).and_return(homewiki_wiki_edits)
    expect(WikiEdits).to receive(:new).with(en_wiki).and_return(en_wiki_edits)

    expect(homewiki_wiki_edits).to receive(:create_account)
      .with(creator:, username: anything, email: anything, reason: anything)
      .and_call_original
    expect(en_wiki_edits).to receive(:create_account)
      .with(creator: super_admin, username: anything, email: anything, reason: anything)
      .and_call_original
    subject
  end

  it 'retries account creation when the main creator account gets a CAPTCHA' do
    SpecialUsers.set_user(:backup_account_creator, super_admin.username)
    # This will stub the request so that it fails with the appropriate
    # error message, which in turn will change the creator to the super admin
    stub_account_creation_failure_captcha(wiki: home_wiki)
    stub_account_creation(wiki: en_wiki)
    expect(WikiEdits).to receive(:new).twice.and_call_original
    expect(WikiEdits).to receive(:new).with(home_wiki).and_return(homewiki_wiki_edits)
    expect(WikiEdits).to receive(:new).with(en_wiki).and_return(en_wiki_edits)
    expect(homewiki_wiki_edits).to receive(:create_account)
      .with(creator:, username: anything, email: anything, reason: anything)
      .and_call_original
    expect(en_wiki_edits).to receive(:create_account)
      .with(creator: super_admin, username: anything, email: anything, reason: anything)
      .and_call_original
    subject
  end

  it 'only retries account creation if the request fails because of expected failure messages' do
    SpecialUsers.set_user(:backup_account_creator, super_admin.username)
    stub_account_creation_failure_unexpected(wiki: home_wiki)
    expect(WikiEdits).to receive(:new).twice.and_call_original
    expect(WikiEdits).to receive(:new).with(home_wiki).and_return(homewiki_wiki_edits)
    expect(homewiki_wiki_edits).to receive(:create_account)
      .with(creator:, username: anything, email: anything, reason: anything)
      .and_call_original
    expect(en_wiki_edits).not_to receive(:create_account)
      .with(creator: super_admin, username: anything, email: anything, reason: anything)
    subject
    expect(RequestedAccount.count).to eq(1)
  end
end
