# frozen_string_literal: true

require 'rails_helper'

describe AddSandboxTemplate do
  let(:course) { create(:course, home_wiki_id: 1) }
  let(:user) { create(:user) }
  let(:enrolling_user) { create(:user, username: 'Belajane41') }
  let(:no_template) { 'No default or sandbox template present.' }
  let(:sandbox) { "User:#{enrolling_user.username}/sandbox" }
  let(:sandbox_template) { "{{#{ENV['dashboard_url']} sandbox}}" }
  let(:default_template) { '{{user sandbox}}' }

  it 'does not add sandbox template twice' do
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(sandbox_template)
    expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
    expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
    described_class.new(home_wiki: course.home_wiki, sandbox:,
                        sandbox_template:, current_user: user)
  end

  it 'replaces default template with sandbox template' do
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(default_template)
    expect_any_instance_of(WikiEdits).not_to receive(:add_to_page_top)
    expect_any_instance_of(WikiEdits).to receive(:post_whole_page).once
    described_class.new(home_wiki: course.home_wiki, sandbox:,
                        sandbox_template:, current_user: user)
  end

  it 'adds sandbox template' do
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(no_template)
    expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).once
    expect_any_instance_of(WikiEdits).not_to receive(:post_whole_page)
    described_class.new(home_wiki: course.home_wiki, sandbox:,
                        sandbox_template:, current_user: user)
  end
end
