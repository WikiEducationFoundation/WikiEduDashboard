# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/replica"

describe Replica do
  describe 'API requests' do
    it 'returns revisions from this term' do
      VCR.use_cassette 'replica/revisions' do
        all_users = [
          build(:user, username: 'ELE427'),
          build(:user, username: 'Ragesoss'),
          build(:user, username: 'Mrbauer1234')
        ]
        rev_start = 2014_01_01_003430
        rev_end = 2014_12_31_003430

        response = Replica.new.get_revisions(all_users, rev_start, rev_end)

        # This count represents the number of pages in a subset of namespaces
        # edited by the users, not the number of revisions. Revisions are child
        # elements of the page ids. Value may change slightly if old revisions
        # get deleted on Wikipedia.
        expect(response.count).to eq(222)

        # Make sure we handle the case of zero revisions.
        rev_start = 2015_05_05
        rev_end = 2015_05_06
        response = Replica.new.get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(0)

        # Make sure we handle the case of one revision.
        rev_start = 2015_05_08
        rev_end = 2015_05_09
        response = Replica.new.get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(1)
      end
    end

    it 'works for users with a reserved url characters in the name' do
      VCR.use_cassette 'replica/comma' do
        comma_user = build(:user,
                           id: 17137867,
                           username: 'JRicker,PhD')
        rev_start = 2015_01_01
        rev_end = 2016_01_01
        response = Replica.new.get_revisions([comma_user], rev_start, rev_end)
        expect(response.count).to be > 1

        ampersand_user = build(:user,
                               id: 22403865,
                               username: 'Evol&Glass')
        response = Replica.new.get_revisions([ampersand_user], rev_start, rev_end)
        expect(response.count).to be > 1

        apostrophe_user = build(:user,
                                id: 26211578,
                                username: "Jack's nomadic mind")
        response = Replica.new.get_revisions([apostrophe_user], rev_start, rev_end)
        expect(response.count).to be > 1

        rev_start = 2008_01_01
        rev_end = 2010_01_01
        exclamation_user = build(:user,
                                 id: 11274650,
                                 username: '!!Aaapplesauce')
        response = Replica.new.get_revisions([exclamation_user], rev_start, rev_end)
        expect(response.count).to be > 1
      end
    end

    it 'returns training status' do
      VCR.use_cassette 'replica/training' do
        all_users = [
          { 'username' => 'ELE427' }, # has not completed
          { 'username' => 'Ragesoss' }, # has completed
          { 'username' => 'Mrbauer1234' }, # has not completed
          { 'username' => "Jack's nomadic mind" }, # has completed
          { 'username' => 'Sage (Wiki Ed)' } # has completed
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.new.get_user_info(all_users)
        trained = response.reduce(0) { |a, e| a + e['trained'].to_i }
        expect(trained).to eq(3)
      end
    end

    it 'returns system parameter for dashboard edits' do
      VCR.use_cassette 'replica/system_edits' do
        all_users = [
          build(:user, username: 'Petra Sen')
        ]
        rev_start = 2016_09_20_003430
        rev_end = 2016_09_22_003430
        response = Replica.new.get_revisions(all_users, rev_start, rev_end)
        dashboard_edit_system_status = response.dig('51688052','revisions',0,'system')
        expect(dashboard_edit_system_status).to eq('true')
      end
    end

    it 'returns global ids' do
      VCR.use_cassette 'replica/training' do
        all_users = [
          { 'username' => 'Ragesoss' },
          { 'username' => 'Ragesock' }
        ]
        all_users.each_with_index do |u, i|
          all_users[i] = OpenStruct.new u
        end
        response = Replica.new.get_user_info(all_users)
        expect(response[1]['global_id']).to eq('827')
        expect(response[0]['global_id']).to eq('14093230')
      end
    end

    it 'returns a list of existing articles' do
      VCR.use_cassette 'replica/articles' do
        article_titles = [
          { 'title' => 'Autism' }, # exists in namespace 0, 1
          { 'title' => 'Allegiance' }, # exists in namespace 0, 1
          # Test with URI reserved characters
          { 'title' => "Broussard's" }, # exists in namespace 0, 1
          { 'title' => 'Procter_&_Gamble' }, # exists in namespace 0, 1, 10, 11
          # Test with special characters
          { 'title' => 'Paul_Cézanne' }, # exists in namespace 0, 1, 10, 11
          { 'title' => 'Mmilldev/sandbox' }, # exists in namespace 2
          { 'title' => 'THIS_ARTICLE_DOES_NOT_EXIST' }
        ]
        response = Replica.new.get_existing_articles_by_title(article_titles)
        expect(response.size).to eq(15)
      end
    end

    it 'functions identically on non-English wikis' do
      VCR.use_cassette 'replica/es_revisions' do
        all_users = [
          build(:user, username: 'AndresAlvarezGalina95', id: 3556537),
          build(:user, username: 'Patyelena25', id: 3471984),
          build(:user, username: 'Lizmich91', id: 3558536)
        ]

        rev_start = 2015_02_12_003430
        rev_end = 2015_03_10_003430

        es_wiki = Wiki.new(language: 'es', project: 'wikipedia')
        response = Replica.new(es_wiki).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(24)
      end
    end

    it 'functions identically on non-English wikis' do
      VCR.use_cassette 'replica/es_revisions' do
        all_users = [
          build(:user, username: 'Ragesoss')
        ]

        rev_start = 2016_03_09_003430
        rev_end = 2016_12_02_003430

        wikidata = Wiki.new(language: nil, project: 'wikidata')
        response = Replica.new(wikidata).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(12)
      end
    end
  end

  describe 'error handling' do
    let(:all_users) do
      [build(:user, username: 'ELE427'),
       build(:user, username: 'Ragesoss'),
       build(:user, username: 'Mrbauer1234')]
    end

    it 'handles timeout errors' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_raise(Errno::ETIMEDOUT)
      rev_start = 2014_01_01_003430
      rev_end = 2014_12_31_003430

      response = Replica.new.get_revisions(all_users, rev_start, rev_end)
      expect(response).to be_empty
    end

    it 'handles connection refused errors' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_raise(Errno::ECONNREFUSED)

      response = Replica.new.get_user_info(all_users)
      expect(response).to be_nil
    end

    it 'handles failed queries' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_return(status: 200, body: '{ "success": false, "data": [] }', headers: {})
      response = Replica.new.get_user_info(all_users)
      expect(response).to be_nil
    end

    it 'handles successful empty responses' do
      stub_request(:any, %r{http://tools.wmflabs.org/.*})
        .to_return(status: 200, body: '{ "success": true, "data": [] }', headers: {})
      response = Replica.new.get_user_info(all_users)
      expect(response).to eq([])
    end
  end
end
