# frozen_string_literal: true

# == Schema Information
#
# Table name: commons_uploads
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  file_name   :string(2000)
#  uploaded_at :datetime
#  usage_count :integer
#  created_at  :datetime
#  updated_at  :datetime
#  thumburl    :string(2000)
#  thumbwidth  :string(255)
#  thumbheight :string(255)
#  deleted     :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe CommonsUpload, type: :model do
  describe '#url' do
    it 'should return the url of the Commons file page' do
      upload = create(:commons_upload,
                      file_name: 'File:MyFile.jpg')
      expect(upload.url)
        .to eq('https://commons.wikimedia.org/wiki/File:MyFile.jpg')
    end
  end
end
