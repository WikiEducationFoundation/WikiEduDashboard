# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/commons"

describe Commons do
  describe '.get_uploads' do
    it 'should get upload data for a user with many uploads' do
      VCR.use_cassette 'commons/get_uploads_many' do
        user = create(:user,
                      username: 'Ragesoss')
        response = Commons.get_uploads [user]
        expect(response.count).to(satisfy { |x| x > 3000 })
        expect(response[0]['timestamp']).not_to be_nil
        expect(response[0]['title']).not_to be_nil
        expect(response[0]['user']).not_to be_nil
        expect(response[0]['pageid']).not_to be_nil
      end
    end

    it 'should handle a user with no uploads' do
      VCR.use_cassette 'commons/get_uploads_none' do
        user = create(:user,
                      username: 'Ragetest 7')
        response = Commons.get_uploads [user]
        expect(response).to eq([])
      end
    end

    it 'should handle a user with one upload' do
      VCR.use_cassette 'commons/get_uploads_one' do
        user = create(:user,
                      username: 'Ameily radke')
        response = Commons.get_uploads [user]
        expect(response.count).to eq(1)
      end
    end
  end

  describe '.get_usages' do
    it 'should get usage data for a widely-used file' do
      VCR.use_cassette 'commons/get_usage_lots' do
        upload = create(:commons_upload,
                        id: 6428847,
                        file_name: 'File:Example.jpg')
        response = Commons.get_usages [upload]
        expect(response.count).to(satisfy { |x| x > 12 })
      end
    end

    it 'should get usage data for an unused file' do
      VCR.use_cassette 'commons/get_usage_none' do
        # rubocop:disable Metrics/LineLength
        upload = create(:commons_upload,
                        id: 39997956,
                        file_name: 'File:Designing Internet Research class at University of Washington, 2015-04-28 21.jpg')
        # rubocop:enable Metrics/LineLength
        response = Commons.get_usages [upload]
        expect(response).to eq([])
      end
    end

    it 'should get usage data for a file used only once' do
      VCR.use_cassette 'commons/get_uploads_one' do
        upload = create(:commons_upload,
                        id: 39636530,
                        file_name: 'File:Paper prototype of website user interface, 2015-04-16.jpg')
        response = Commons.get_usages [upload]
        expect(response.count).to eq(1)
      end
    end

    it 'should not fail when missing files are queried' do
      VCR.use_cassette 'commons/missing_files' do
        upload = create(:commons_upload,
                        id: 541408,
                        file_name: 'File:Haeckel Stephoidea.jpg')
        missing = create(:commons_upload,
                         id: 0)
        response = Commons.get_usages [missing]
        expect(response).to eq([])
        response = Commons.get_usages [missing, upload]
        expect(response).not_to be_empty
      end
    end
  end

  describe '.find_missing_files' do
    let(:deleted_file) { create(:commons_upload, id: 4) }
    let(:existing_file) { create(:commons_upload, id: 20523186) }

    it 'returns CommonsUploads that are reported missing' do
      VCR.use_cassette 'commons/find_missing_files' do
        result = Commons.find_missing_files([deleted_file, existing_file])
        expect(result).to include deleted_file
        expect(result).not_to include existing_file
      end
    end

    it 'returns an empty array if all files exist' do
      VCR.use_cassette 'commons/find_missing_files' do
        result = Commons.find_missing_files([existing_file])
        expect(result).to eq([])
      end
    end
  end

  describe '.get_urls' do
    it 'should get thumbnail url data for files' do
      VCR.use_cassette 'commons/get_urls' do
        create(:commons_upload,
               id: 541408,
               file_name: 'File:Haeckel Stephoidea.jpg')
        response = Commons.get_urls(CommonsUpload.all)
        id = response[0]['pageid']
        expect(id).to eq(541408)
        info = response[0]['imageinfo'][0]
        expect(info['thumburl']).to be_a(String)
        # Now add a second file and try again
        create(:commons_upload,
               id: 543690,
               file_name: 'File:Haeckel Spumellaria.jpg ')
        response = Commons.get_urls(CommonsUpload.all)
        id0 = response[0]['pageid']
        expect(id0).to eq(541408)
        id1 = response[1]['pageid']
        expect(id1).to eq(543690)
      end
    end

    it 'should not fail for files that have placeholder thumbnails' do
      VCR.use_cassette 'commons/get_urls_with_placeholder_thumbnails' do
        # MediaWiki can't generate a real thumbnail of this file.
        # It used to cause a 'iiurlparamnormal' error, but since late February
        # 2016, it fails gracefully with a placeholder image.
        create(:commons_upload,
               id: 28591020,
               file_name: 'File:Jewish Encyclopedia Volume 6.pdf',
               thumburl: nil)
        response = Commons.get_urls(CommonsUpload.all)
        expect(response).not_to be_empty
      end
    end
  end

  describe '.api_get' do
    it 'should handle typical network errors' do
      stub_commons_503_error
      create(:commons_upload,
             id: 541408,
             file_name: 'File:Haeckel Stephoidea.jpg')
      response = Commons.get_urls(CommonsUpload.all)
      expect(response.empty?).to be true
    end

    it 'should raise unexpected errors' do
      stub_request(:get, /.*commons.wikimedia.org.*/).to_raise(StandardError)
      create(:commons_upload,
             id: 541408,
             file_name: 'File:Haeckel Stephoidea.jpg')
      expect { Commons.get_urls(CommonsUpload.all) }
        .to raise_error(StandardError)
    end
  end
end
