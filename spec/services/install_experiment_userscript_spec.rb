# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe InstallExperimentUserscript do
  let(:course) { create(:course, start: Date.new(2026, 9, 1)) }
  let(:user) { create(:user, wiki_token: 'token', wiki_secret: 'secret') }
  let(:courses_user) do
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end
  let(:record) do
    ExperimentCoursesUser.create!(experiment_slug: 'fall_2026_research',
                                  courses_user:, status: :opted_in)
  end
  let(:experiment) { Fall2026ResearchExperiment.new }

  before { allow(Features).to receive(:disable_wiki_output?).and_return(false) }

  it 'installs the userscript and records the timestamp on success' do
    allow_any_instance_of(WikiEdits).to receive(:add_to_page_top)
      .and_return('edit' => { 'result' => 'Success' })
    service = described_class.new(record, experiment)
    expect(service.status).to eq(:installed)
    expect(record.reload.userscript_installed_at).to be_present
  end

  it 'reports reauth_required without invalidating the token on a permission error' do
    allow_any_instance_of(WikiEdits).to receive(:add_to_page_top)
      .and_return('error' => { 'code' => 'permissiondenied' })
    service = described_class.new(record, experiment)
    expect(service.status).to eq(:reauth_required)
    expect(record.reload.userscript_installed_at).to be_nil
    expect(user.reload.wiki_token).to eq('token')
  end

  # Confirmed against production: a consumer lacking the editmyuserjs grant
  # returns this code when editing the user's own common.js.
  it 'treats a mycustomjsprotected response (missing editmyuserjs grant) as reauth_required' do
    allow_any_instance_of(WikiEdits).to receive(:add_to_page_top)
      .and_return('error' => { 'code' => 'mycustomjsprotected' })
    expect(described_class.new(record, experiment).status).to eq(:reauth_required)
  end

  it 'treats a readapidenied response (under-scoped token) as reauth_required' do
    allow_any_instance_of(WikiEdits).to receive(:add_to_page_top)
      .and_return('error' => { 'code' => 'readapidenied' })
    expect(described_class.new(record, experiment).status).to eq(:reauth_required)
  end

  it 'reports an error for other failures' do
    allow_any_instance_of(WikiEdits).to receive(:add_to_page_top)
      .and_return('error' => { 'code' => 'somethingelse' })
    expect(described_class.new(record, experiment).status).to eq(:error)
  end

  it 'does nothing when wiki output is disabled' do
    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
    expect(described_class.new(record, experiment).status).to eq(:disabled)
  end
end
