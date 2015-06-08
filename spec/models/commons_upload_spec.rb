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
