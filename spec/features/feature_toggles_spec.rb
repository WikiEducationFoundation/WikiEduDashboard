# frozen_string_literal: true

require 'rails_helper'

def stylesheet_manifest_file_exists?
  manifest_path = "#{Rails.root}/public/assets/stylesheets/rev-manifest.json"
  File.read(manifest_path)
  true
rescue Errno::ENOENT
  false
end

describe 'Feature toggles', type: :feature, js: true do
  describe 'hot_loading?', js_error_expected: true do
    context 'when enabled' do
      before { allow(Features).to receive(:hot_loading?).and_return(true) }

      it 'renders the home page' do
        visit root_path
      end
    end

    context 'when disabled' do
      before { allow(Features).to receive(:hot_loading?).and_return(false) }

      it 'renders the home page' do
        # This breaks of the manifest file is absent, which is the case when
        # `gulp hot-dev` is running.
        visit root_path if stylesheet_manifest_file_exists?
      end
    end
  end
end
