require 'rails_helper'
require "#{Rails.root}/lib/replica"

describe Replica do
  describe 'API requests' do
    it 'should connect to replica tools' do
      response = Replica.connect_to_tool
      # rubocop:disable Metrics/LineLength
      expect(response).to eq('You have successfully reached to the WikiEduDashboard tool hosted by the Wikimedia Tool Labs.')
      # rubocop:enable Metrics/LineLength
    end

    it 'should handle timeout errors' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_raise(Errno::ETIMEDOUT)
      all_users = [
        build(:user, username: 'ELE427', id: 22905965),
        build(:user, username: 'Ragesoss', id: 319203),
        build(:user, username: 'Mrbauer1234', id: 23011474)
      ]
      rev_start = 2014_01_01_003430
      rev_end = 2014_12_31_003430

      response = Replica.get_revisions(all_users, rev_start, rev_end)
      expect(response).to be_empty
    end

    it 'should handle connection refused errors' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_raise(Errno::ECONNREFUSED)
      all_users = [
        build(:user, username: 'ELE427', id: 22905965),
        build(:user, username: 'Ragesoss', id: 319203),
        build(:user, username: 'Mrbauer1234', id: 23011474)
      ]

      response = Replica.get_user_info(all_users)
      expect(response).to be_nil
    end

    it 'should return revisions from this term' do
      VCR.use_cassette 'replica/revisions' do
        all_users = [
          build(:user, username: 'ELE427', id: 22905965),
          build(:user, username: 'Ragesoss', id: 319203),
          build(:user, username: 'Mrbauer1234', id: 23011474)
        ]
        rev_start = 2014_01_01_003430
        rev_end = 2014_12_31_003430

        response = Replica.get_revisions(all_users, rev_start, rev_end)

        # This count represents the number of pages in a subset of namespaces
        # edited by the users, not the number of revisions. Revisions are child
        # elements of the page ids.
        expect(response.count).to eq(223)

        # Make sure we handle the case of zero revisions.
        rev_start = 2015_05_05
        rev_end = 2015_05_06
        response = Replica.get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(0)

        # Make sure we handle the case of one revision.
        rev_start = 2015_05_08
        rev_end = 2015_05_09
        response = Replica.get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(1)
      end
    end

    it 'should work for users with a reserved url characters in the name' do
      VCR.use_cassette 'replica/comma' do
        comma_user = build(:user,
                           id: 17137867,
                           username: 'JRicker,PhD')
        rev_start = 2015_01_01
        rev_end = 2016_01_01
        response = Replica.get_revisions([comma_user], rev_start, rev_end)
        expect(response.count).to be > 1

        ampersand_user = build(:user,
                               id: 22403865,
                               username: 'Evol&Glass')
        response = Replica.get_revisions([ampersand_user], rev_start, rev_end)
        expect(response.count).to be > 1

        apostrophe_user = build(:user,
                                id: 26211578,
                                username: "Jack's nomadic mind")
        response = Replica.get_revisions([apostrophe_user], rev_start, rev_end)
        expect(response.count).to be > 1

        rev_start = 2008_01_01
        rev_end = 2010_01_01
        exclamation_user = build(:user,
                                 id: 11274650,
                                 username: '!!Aaapplesauce')
        response = Replica.get_revisions([exclamation_user], rev_start, rev_end)
        expect(response.count).to be > 1
      end
    end

    it 'should return training status' do
      VCR.use_cassette 'replica/training' do
        all_users = [
          { 'id' => '22905965' }, # has not completed
          { 'id' => '319203' }, # has completed
          { 'id' => '23011474' }, # has not completed
          { 'id' => '4543197' }, # has completed
          { 'id' => '21515199' } # has completed
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.get_user_info(all_users)
        trained = response.reduce(0) { |a, e| a + e['trained'].to_i }
        expect(trained).to eq(3)
      end
    end

    it 'should return global ids' do
      VCR.use_cassette 'replica/training' do
        all_users = [
          { 'id' => '319203' },
          { 'id' => '4543197' }
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.get_user_info(all_users)
        expect(response[0]['global_id']).to eq('827')
        expect(response[1]['global_id']).to eq('14093230')
      end
    end

    it 'should update usernames after name changes' do
      VCR.use_cassette 'replica/training' do
        create(:user, username: 'old_username')
        expect(User.all.first.username).to eq('old_username')
        response = Replica.get_user_info User.all
        expect(response[0]['wiki_id']).to eq('Ragesock')
      end
    end

    it 'should return a list of existing articles' do
      VCR.use_cassette 'replica/articles' do
        article_titles = [
          { 'title' => 'Autism' }, # exists in namespace 0, 1
          { 'title' => 'Allegiance' }, # exists in namespace 0, 1
          # Test with URI reserved characters
          { 'title' => "Broussard's" }, # exists in namespace 0, 1
          { 'title' => 'Procter & Gamble' }, # exists in namespace 0, 1, 10, 11
          # Test with special characters
          { 'title' => 'Paul Cézanne' }, # exists in namespace 0, 1, 10, 11
          { 'title' => 'Mmilldev/sandbox' }, # exists in namespace 2
          { 'title' => 'THIS ARTICLE_DOES NOT_EXIST' }
        ]
        response = Replica.get_existing_articles_by_title(article_titles)
        expect(response.size).to eq(15)
      end
    end

    it 'should function identically on non-English wikis' do
      VCR.use_cassette 'replica/es_revisions' do
        all_users = [
          build(:user, username: 'AndresAlvarezGalina95', id: 3556537),
          build(:user, username: 'Patyelena25', id: 3471984),
          build(:user, username: 'Lizmich91', id: 3558536)
        ]

        rev_start = 2015_02_12_003430
        rev_end = 2015_03_10_003430

        response = Replica.get_revisions(all_users, rev_start, rev_end, 'es')
        expect(response.count).to eq(24)
      end
    end
  end
end
