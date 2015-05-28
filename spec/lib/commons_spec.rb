require 'rails_helper'
require "#{Rails.root}/lib/commons"

describe Commons do
  describe '.get_uploads' do
    it 'should get upload data for a user with many uploads' do
      VCR.use_cassette 'commons/get_uploads_many' do
        user = create(:user,
                      wiki_id: 'Ragesoss')
        response = Commons.get_uploads [user]
        expect(response.count).to satisfy { |x| x > 3000 }
        expect(response[0]['timestamp']).not_to be_nil
        expect(response[0]['title']).not_to be_nil
        expect(response[0]['user']).not_to be_nil
        expect(response[0]['pageid']).not_to be_nil
      end
    end

    it 'should handle a user with no uploads' do
      VCR.use_cassette 'commons/get_uploads_none' do
        user = create(:user,
                      wiki_id: 'Ragetest 7')
        response = Commons.get_uploads [user]
        expect(response).to eq([])
      end
    end

    it 'should handle a user with one upload' do
      VCR.use_cassette 'commons/get_uploads_one' do
        user = create(:user,
                      wiki_id: 'Ameily radke')
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
        expect(response.count).to satisfy { |x| x > 12 }
      end
    end

    it 'should get usage data for an unused file' do
      VCR.use_cassette 'commons/get_usage_none' do
        # rubocop:disable Metrics/LineLength
        user = create(:commons_upload,
                      id: 39997956,
                      file_name: 'File:Designing Internet Research class at University of Washington, 2015-04-28 21.jpg')
        # rubocop:enable Metrics/LineLength
        response = Commons.get_usages [user]
        expect(response).to eq([])
      end
    end

    it 'should get usage data for a file used only once' do
      VCR.use_cassette 'commons/get_uploads_one' do
        # rubocop:disable Metrics/LineLength
        user = create(:commons_upload,
                      id: 39636530,
                      file_name: 'File:Paper prototype of website user interface, 2015-04-16.jpg')
        # rubocop:enable Metrics/LineLength
        response = Commons.get_usages [user]
        expect(response.count).to eq(1)
      end
    end
  end
end
