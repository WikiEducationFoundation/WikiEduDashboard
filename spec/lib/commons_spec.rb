require 'rails_helper'
require "#{Rails.root}/lib/commons"

describe Commons do
  describe '.import_all_uploads' do
    it 'should find and record files uploaded to Commons' do
      create(:user,
              wiki_id: 'Ragesoss')
      VCR.use_cassette 'commons/import_all_uploads' do
        Commons.import_all_uploads
        expect(CommonsUpload.all.count).to eq(3194)
      end
    end
  end

  describe '.update_usage_count' do
    it 'should find and record files uploaded to Commons' do
      create(:user,
              wiki_id: 'Ragesoss')
      VCR.use_cassette 'commons/import_all_uploads' do
        Commons.import_all_uploads
      end
      VCR.use_cassette 'commons/update_usage_count' do
        Commons.update_usage_count
        expect(CommonsUpload.first.usage_count).to eq(1)
        pp CommonsUpload.sum(:usage_count)
      end
    end
  end
end
