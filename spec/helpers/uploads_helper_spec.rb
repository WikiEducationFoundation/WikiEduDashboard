# frozen_string_literal: true

require 'rails_helper'

describe UploadsHelper do
  describe '.pretty_filename' do
    it 'should format a filename nicely for display' do
      upload = build(:commons_upload,
                     file_name: 'File:My file.jpg')
      result = pretty_filename(upload)
      expect(result).to eq('My file.jpg')
    end
  end
end
