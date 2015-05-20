require 'rails_helper'
require "#{Rails.root}/lib/importers/upload_importer"

describe UploadImporter do
  describe '.import_all_uploads' do
    it 'should find and record files uploaded to Commons' do
      create(:user,
             wiki_id: 'Ragesoss')
      VCR.use_cassette 'commons/import_all_uploads' do
        UploadImporter.import_all_uploads(User.all)
        expect(CommonsUpload.all.count).to eq(3194)
      end
    end
  end

  describe '.update_usage_count' do
    it 'should find and record files uploaded to Commons' do
      create(:user,
             wiki_id: 'Ragesoss')
      VCR.use_cassette 'commons/import_all_uploads' do
        UploadImporter.import_all_uploads(User.all)
      end
      VCR.use_cassette 'commons/update_usage_count' do
        UploadImporter.update_usage_count(CommonsUpload.all)
        expect(CommonsUpload.first.usage_count).to eq(1)
      end
    end
  end
end
