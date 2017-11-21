# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/replica"

describe Replica do
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
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

        response = Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end)

        # This count represents the number of pages in a subset of namespaces
        # edited by the users, not the number of revisions. Revisions are child
        # elements of the page ids. Value may change slightly if old revisions
        # get deleted on Wikipedia.
        expect(response.count).to eq(222)

        # Make sure we handle the case of zero revisions.
        rev_start = 2015_05_05
        rev_end = 2015_05_06
        response = Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(0)

        # Make sure we handle the case of one revision.
        rev_start = 2015_05_08
        rev_end = 2015_05_09
        response = Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
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
        response = Replica.new(en_wiki).get_revisions([comma_user], rev_start, rev_end)
        expect(response.count).to be > 1

        ampersand_user = build(:user,
                               id: 22403865,
                               username: 'Evol&Glass')
        response = Replica.new(en_wiki).get_revisions([ampersand_user], rev_start, rev_end)
        expect(response.count).to be > 1

        apostrophe_user = build(:user,
                                id: 26211578,
                                username: "Jack's nomadic mind")
        response = Replica.new(en_wiki).get_revisions([apostrophe_user], rev_start, rev_end)
        expect(response.count).to be > 1

        rev_start = 2008_01_01
        rev_end = 2010_01_01
        exclamation_user = build(:user,
                                 id: 11274650,
                                 username: '!!Aaapplesauce')
        response = Replica.new(en_wiki).get_revisions([exclamation_user], rev_start, rev_end)
        expect(response.count).to be > 1
      end
    end

    it 'returns system parameter for dashboard edits' do
      VCR.use_cassette 'replica/system_edits' do
        all_users = [
          build(:user, username: 'Petra Sen')
        ]
        rev_start = 2016_09_20_003430
        rev_end = 2016_09_22_003430
        response = Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
        dashboard_edit_system_status = response.dig('51688052', 'revisions', 0, 'system')
        expect(dashboard_edit_system_status).to eq('true')
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
        response = Replica.new(en_wiki).get_existing_articles_by_title(article_titles)
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
        expect(response.count).to eq(22)
      end
    end

    it 'functions identically on wikidata' do
      VCR.use_cassette 'replica/wikidata_revisions' do
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

    it 'functions identically on multilingual wikisource' do
      VCR.use_cassette 'replica/wikisource_revisions' do
        all_users = [
          build(:user, username: 'Jimregan')
        ]

        rev_start = 2017_03_27_003430
        rev_end = 2017_03_28_000000

        wikisource = Wiki.new(language: nil, project: 'wikisource')
        response = Replica.new(wikisource).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(28)
      end
    end

    it 'functions identically on wikimedia incubator' do
      VCR.use_cassette 'replica/wikimedia_incubator_revisions' do
        all_users = [
          build(:user, username: 'Daad Ikram')
        ]

        rev_start = 2017_03_11_000000
        rev_end = 2017_03_17_000000

        incubator = Wiki.new(language: 'incubator', project: 'wikimedia')
        response = Replica.new(incubator).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(1)
      end
    end
  end

  describe 'error handling' do
    let(:all_users) do
      [build(:user, username: 'ELE427'),
       build(:user, username: 'Ragesoss'),
       build(:user, username: 'Mrbauer1234')]
    end
    let(:rev_start) { 2014_01_01_003430 }
    let(:rev_end) { 2014_12_31_003430 }
    let(:subject) { Replica.new(en_wiki).get_revisions(all_users, rev_start, rev_end) }

    it 'handles timeout errors' do
      stub_request(:any, %r{https://tools.wmflabs.org/.*})
        .to_raise(Errno::ETIMEDOUT)
      expect(subject).to be_empty
    end

    it 'handles connection refused errors' do
      stub_request(:any, %r{https://tools.wmflabs.org/.*})
        .to_raise(Errno::ECONNREFUSED)

      expect(subject).to be_empty
    end

    it 'handles failed queries' do
      stub_request(:any, %r{https://tools.wmflabs.org/.*})
        .to_return(status: 200, body: '{ "success": false, "data": [] }', headers: {})
      expect(subject).to be_empty
    end

    it 'handles successful empty responses' do
      stub_request(:any, %r{https://tools.wmflabs.org/.*})
        .to_return(status: 200, body: '{ "success": true, "data": [] }', headers: {})
      expect(subject).to be_empty
    end
  end
end
