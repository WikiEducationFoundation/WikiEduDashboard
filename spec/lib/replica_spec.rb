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
        { 'wiki_id' => 'ELE427' },
        { 'wiki_id' => 'Ragesoss' },
        { 'wiki_id' => 'Mrbauer1234' }
      ]
      rev_start = 2014_01_01_003430
      rev_end = 2014_12_31_003430

      all_users.each_with_index do |u, i|
        all_users[i] = OpenStruct.new u
      end
      response = Replica.get_revisions(all_users, rev_start, rev_end)
      expect(response).to be_empty
    end

    it 'should handle connection refused errors' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_raise(Errno::ECONNREFUSED)
      all_users = [
        { 'id' => '319203' },
        { 'id' => '4543197' }
      ]
      all_users.each_with_index do |u, i|
        all_users[i] = OpenStruct.new u
      end
      response = Replica.get_user_info(all_users)
      expect(response).to be_nil
    end

    # rubocop:disable Style/NumericLiterals
    it 'should return revisions from this term' do
      VCR.use_cassette 'replica/revisions' do
        all_users = [
          { 'wiki_id' => 'ELE427' },
          { 'wiki_id' => 'Ragesoss' },
          { 'wiki_id' => 'Mrbauer1234' }
        ]
        rev_start = 2014_01_01_003430
        rev_end = 2014_12_31_003430

        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
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
    # rubocop:enable Style/NumericLiterals

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

    it 'should get an id from a username' do
      VCR.use_cassette 'replica/get_user_id' do
        # make sure usernames with spaces get handled correctly
        response = Replica.get_user_id('LiAnna (Wiki Ed)')
        expect(response).to eq('21102089')
        # make sure unicode works
        response = Replica.get_user_id('ערן')
        expect(response).to eq('7201119')
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
        create(:user, wiki_id: 'old_username')
        expect(User.all.first.wiki_id).to eq('old_username')
        response = Replica.get_user_info User.all
        expect(response[0]['wiki_id']).to eq('Ragesock')
      end
    end

    it 'should return a list of existing articles' do
      VCR.use_cassette 'replica/articles' do
        article_titles = [
          { 'title' => 'Autism' }, # exists in namespace 0, 1
          { 'title' => 'Allegiance' }, # exists in namespace 0, 1
          #  Test with special characters)
          { 'title' => 'Paul Cézanne' }, # exists in namespace 0, 1, 10, 11
          { 'title' => 'Mmilldev/sandbox' }, # exists in namespace 2
          { 'title' => 'THIS ARTICLE_DOES NOT_EXIST' }
        ]
        response = Replica.get_existing_articles_by_title(article_titles)
        expect(response.size).to eq(9)
      end
    end

    it 'should function identically on non-English wikis' do
      VCR.use_cassette 'replica/es_revisions' do
        allow(Figaro.env).to receive(:wiki_language).and_return('es')
        all_users = [
          { 'wiki_id' => 'AndresAlvarezGalina95' },
          { 'wiki_id' => 'Patyelena25' },
          { 'wiki_id' => 'Lizmich91' }
        ]
        # rubocop:disable Style/NumericLiterals
        rev_start = 2015_02_12_003430
        rev_end = 2015_03_10_003430
        # rubocop:enable Style/NumericLiterals

        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(25)
      end
    end
  end
end
