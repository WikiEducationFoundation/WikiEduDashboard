# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_preferences_manager"

describe WikiPreferencesManager do
  before do
    allow(Features).to receive(:disable_wiki_output?).and_return(false)
  end
  let(:user) { create(:user, wiki_token: 'foo', wiki_secret: 'bar') }
  let(:manager) { described_class.new(user: user) }

  # As with WikiEdits, we're only testing that the normal responses get handled
  # properly. We just stub the mediawiki API.
  describe 'enable_visual_editor' do
    it 'handles successful updates' do
      stub_oauth_options_success
      result = manager.enable_visual_editor
      expect(result['options']).to eq('success')
    end

    it 'handles updates that include warnings' do
      stub_oauth_options_warning
      result = manager.enable_visual_editor
      expect(result['warnings']).not_to be_nil
    end
  end
end
