# frozen_string_literal: true

require 'rails_helper'

describe UploadsHelper do
  describe '.pretty_filename' do
    it 'formats a filename nicely for display' do
      upload = build(:commons_upload,
                     file_name: 'File:My file.jpg')
      result = pretty_filename(upload)
      expect(result).to eq('My file.jpg')
    end

    it 'formats a complex filename with encoded characters nicely for display' do
      upload = build(:commons_upload,
                     # rubocop:disable Layout/LineLength
                     file_name: 'File%3AA+sunflower+%F0%9F%8C%BB%F0%9F%8C%BB+in+Kaduna+Polytechnic%2CSabo+Campus.jpg')
      # rubocop:enable Layout/LineLength
      result = pretty_filename(upload)
      expect(result).to eq('A sunflower 🌻🌻 in Kaduna Polytechnic,Sabo Campus.jpg')
    end
  end
end
