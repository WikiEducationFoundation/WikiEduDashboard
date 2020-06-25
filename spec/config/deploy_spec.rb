# frozen_string_literal: true

require 'rails_helper'

describe 'Deployment configuration' do
  it 'verifies that the Capistrano gem version being locked is correct' do
    deploy_config_text = File.read('config/deploy.rb')
    capistrano_version = deploy_config_text.scan(/lock '.*'/)[0].gsub('lock ', '').delete("'")
    expect(Gem.loaded_specs['capistrano'].version.to_s).to eq(capistrano_version)
  end
end
