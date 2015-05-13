require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"

describe WikiEdits do
  describe '.notify_untrained' do
    pending 'should post messages to Wikipedia talk pages'
  end

  describe '.tokens' do
    pending 'should fetch edit tokens for an OAuthed user'
  end

  describe '.api_get' do
    pending 'should send data and tokens to Wikipedia'
  end
end
