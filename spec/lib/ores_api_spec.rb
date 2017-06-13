# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/ores_api"

describe OresApi do
  context 'when the wiki is not a wikipedia' do
    before { stub_wiki_validation }
    let!(:wiki) { create(:wiki, project: 'wikivoyage', language: 'en') }
    let(:subject) { described_class.new(wiki) }
    it 'raises an error' do
      expect { subject }.to raise_error OresApi::InvalidProjectError
    end
  end
end
