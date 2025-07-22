# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/commons"

describe Commons do
  describe '.get_uploads' do
    it 'gets upload data for a user with many uploads' do
      VCR.use_cassette 'commons/get_uploads_many' do
        user = create(:user,
                      username: 'Ragesoss')
        response = described_class.get_uploads [user]
        expect(response.count).to(satisfy { |x| x > 3000 })
        expect(response[0]['timestamp']).not_to be_nil
        expect(response[0]['title']).not_to be_nil
        expect(response[0]['user']).not_to be_nil
        expect(response[0]['pageid']).not_to be_nil
      end
    end

    it 'gets upload data from a particular time period' do
      VCR.use_cassette 'commons/get_uploads_time_limited' do
        user = create(:user,
                      username: 'Ragesoss')
        response = described_class.get_uploads([user], start_date: '2017-01-01'.to_time,
                                                       end_date: '2018-01-01'.to_time)
        expect(response.count).to eq(143)
        expect(response[0]['timestamp']).not_to be_nil
        expect(response[0]['title']).not_to be_nil
        expect(response[0]['user']).not_to be_nil
        expect(response[0]['pageid']).not_to be_nil
      end
    end

    it 'handles a user with no uploads' do
      VCR.use_cassette 'commons/get_uploads_none' do
        user = create(:user,
                      username: 'Ragetest 7')
        response = described_class.get_uploads [user]
        expect(response).to eq([])
      end
    end

    it 'handles a user with one upload' do
      VCR.use_cassette 'commons/get_uploads_one' do
        user = create(:user,
                      username: 'EDA2018')
        response = described_class.get_uploads [user]
        expect(response.count).to eq(1)
      end
    end
  end

  describe '.get_usages' do
    it 'gets usage data for a widely-used file' do
      VCR.use_cassette 'commons/get_usage_lots' do
        upload = create(:commons_upload,
                        id: 1488574,
                        file_name: 'File:Goblet Glass (Banquet).svg')
        response = described_class.get_usages [upload]
        # The response count is the number of separate API queries that are made
        # to get all the results, at 500 results per query.
        # This tests the query continuation flow.
        expect(response.count).to(satisfy { |x| x > 1 })
      end
    end

    it 'gets usage data for an unused file' do
      VCR.use_cassette 'commons/get_usage_none' do
        # rubocop:disable Layout/LineLength
        upload = create(:commons_upload,
                        id: 39997956,
                        file_name: 'File:Designing Internet Research class at University of Washington, 2015-04-28 21.jpg')
        # rubocop:enable Layout/LineLength
        response = described_class.get_usages [upload]
        expect(response).to eq([])
      end
    end

    it 'gets usage data for a file used only once' do
      VCR.use_cassette 'commons/get_uploads_one' do
        upload = create(:commons_upload,
                        id: 39636530,
                        file_name: 'File:Paper prototype of website user interface, 2015-04-16.jpg')
        response = described_class.get_usages [upload]
        expect(response.count).to eq(1)
      end
    end

    it 'does not fail when missing files are queried' do
      VCR.use_cassette 'commons/missing_files' do
        upload = create(:commons_upload,
                        id: 541408,
                        file_name: 'File:Haeckel Stephoidea.jpg')
        missing = create(:commons_upload,
                         id: 0)
        response = described_class.get_usages [missing]
        expect(response).to eq([])
        response = described_class.get_usages [missing, upload]
        expect(response).not_to be_empty
      end
    end
  end

  describe '.find_missing_files' do
    let(:deleted_file) { create(:commons_upload, id: 4) }
    let(:existing_file) { create(:commons_upload, id: 20523186) }

    it 'returns CommonsUploads that are reported missing' do
      VCR.use_cassette 'commons/find_missing_files' do
        result = described_class.find_missing_files([deleted_file, existing_file])
        expect(result).to include deleted_file
        expect(result).not_to include existing_file
      end
    end

    it 'returns an empty array if all files exist' do
      VCR.use_cassette 'commons/find_missing_files' do
        result = described_class.find_missing_files([existing_file])
        expect(result).to eq([])
      end
    end
  end

  describe '.get_urls' do
    it 'gets thumbnail url data for files' do
      VCR.use_cassette 'commons/get_urls' do
        create(:commons_upload,
               id: 541408,
               file_name: 'File:Haeckel Stephoidea.jpg')
        response = described_class.get_urls(CommonsUpload.all)
        id = response[0]['pageid']
        expect(id).to eq(541408)
        info = response[0]['imageinfo'][0]
        expect(info['thumburl']).to be_a(String)
        # Now add a second file and try again
        create(:commons_upload,
               id: 543690,
               file_name: 'File:Haeckel Spumellaria.jpg ')
        response = described_class.get_urls(CommonsUpload.all)
        id0 = response[0]['pageid']
        expect(id0).to eq(541408)
        id1 = response[1]['pageid']
        expect(id1).to eq(543690)
      end
    end

    it 'does not fail for files that have placeholder thumbnails' do
      VCR.use_cassette 'commons/get_urls_with_placeholder_thumbnails' do
        # MediaWiki can't generate a real thumbnail of this file.
        # It used to cause a 'iiurlparamnormal' error, but since late February
        # 2016, it fails gracefully with a placeholder image.
        create(:commons_upload,
               id: 28591020,
               file_name: 'File:Jewish Encyclopedia Volume 6.pdf',
               thumburl: nil)
        response = described_class.get_urls(CommonsUpload.all)
        expect(response).not_to be_empty
      end
    end
  end

  describe '#get_image_data' do
    bad_query = { prop: 'imageinfo', iiprop: 'url', iiurlheight: 480, pageids: [
      107709976, 111662244, 109767821, 109782162, 109782164, 109782168, 109782171, 109782172,
      109782180, 109782183
    ], iilimit: 50 }

    # Testing workaround for MediaWiki bug
    # https://phabricator.wikimedia.org/T101532
    it 'handles broken continues gracefully' do
      VCR.use_cassette 'commons/cotinue_loop' do
        result = described_class.new(bad_query).get_image_data('imageinfo', 'iicontinue')
        expect(result.length).to be > 10
      end
    end
  end

  describe '.api_get' do
    it 'handles typical network errors' do
      stub_commons_503_error
      create(:commons_upload,
             id: 541408,
             file_name: 'File:Haeckel Stephoidea.jpg')
      response = described_class.get_urls(CommonsUpload.all)
      expect(response.empty?).to be true
    end
  end
end
