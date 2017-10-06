# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils"

describe Utils do
  describe '.parse_json' do
    it 'should handle unparseable json' do
      not_json = '<xml_is_great>Wat?</xml_is_great>'
      Utils.parse_json(not_json)
    end
  end
end
