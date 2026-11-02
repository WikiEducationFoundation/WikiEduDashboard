# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/errors/update_service_error_helper"

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

        response = described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end)

        # This count represents the number of pages in a subset of namespaces
        # edited by the users, not the number of revisions. Revisions are child
        # elements of the page ids. Value may change slightly if old revisions
        # get deleted on Wikipedia.
        expect(response.count).to be_within(30).of(224)

        # Make sure we handle the case of zero revisions.
        rev_start = 2015_05_05
        rev_end = 2015_05_06
        response = described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(0)

        # Make sure we handle the case of one revision.
        rev_start = 2015_05_08
        rev_end = 2015_05_09
        response = described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
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
        response = described_class.new(en_wiki).get_revisions([comma_user], rev_start, rev_end)
        expect(response.count).to be > 1

        ampersand_user = build(:user,
                               id: 22403865,
                               username: 'Evol&Glass')
        response = described_class.new(en_wiki).get_revisions([ampersand_user], rev_start, rev_end)
        expect(response.count).to be > 1

        apostrophe_user = build(:user,
                                id: 26211578,
                                username: "Jack's nomadic mind")
        response = described_class.new(en_wiki).get_revisions([apostrophe_user], rev_start, rev_end)
        expect(response.count).to be > 1

        rev_start = 2008_01_01
        rev_end = 2010_01_01
        exclamation_user = build(:user,
                                 id: 11274650,
                                 username: '!!Aaapplesauce')
        response = described_class.new(en_wiki)
                                  .get_revisions([exclamation_user], rev_start, rev_end)
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
        response = described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end)
        dashboard_edit_system_status = response.dig('51688052', 'revisions', 0, 'system')
        expect(dashboard_edit_system_status).to eq('true')
      end
    end

    describe 'Article retrieval' do
      context 'when fetching existing articles' do
        def title_arg(title)
          [{ 'title' => title }]
        end

        def articles_response(title)
          described_class.new(en_wiki).post_existing_articles_by_title(title_arg(title))
        end

        it 'returns article "Allegiance"' do
          VCR.use_cassette 'replica/articles/2' do
            response = articles_response('Allegiance')
            expect(response.size).to eq(2) # exists in namespace 0, 1
          end
        end

        # Test with URI reserved characters
        it 'returns article "Broussard\'s"' do
          VCR.use_cassette 'replica/articles/3' do
            response = articles_response("Broussard's")
            expect(response.size).to eq(2) # exists in namespace 0, 1
          end
        end

        it 'returns article "Procter_&_Gamble"' do
          VCR.use_cassette 'replica/articles/4' do
            response = articles_response('Procter_&_Gamble')
            expect(response.size).to eq(4) # exists in namespace 0, 1, 10, 11
          end
        end

        # Test with special characters
        it 'returns article "Paul_Cézanne"' do
          VCR.use_cassette 'replica/articles/5' do
            response = articles_response('Paul_Cézanne')
            expect(response.size).to eq(4) # exists in namespace 0, 1, 10, 11
          end
        end

        it 'returns article "Mmilldev/sandbox"' do
          VCR.use_cassette 'replica/articles/6' do
            response = articles_response('Mmilldev/sandbox')
            expect(response.size).to eq(1) # exists in namespace 2
          end
        end

        it 'does not return article "THIS_ARTICLE_DOES_NOT_EXIST"' do
          VCR.use_cassette 'replica/articles/7' do
            response = articles_response('THIS_ARTICLE_DOES_NOT_EXIST')
            expect(response.size).to eq(0) # does not exist
          end
        end
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
        response = described_class.new(es_wiki).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(21)
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
        response = described_class.new(wikidata).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(12)
      end
    end

    it 'functions identically for a language code with a hyphen' do
      VCR.use_cassette 'replica/nds_nl_revisions' do
        all_users = [
          build(:user, username: 'Woolters')
        ]

        rev_start = 2021_02_02_003430
        rev_end = 2021_02_04_003430

        nds_nl_wiki = Wiki.new(language: 'nds-nl', project: 'wikipedia')
        response = described_class.new(nds_nl_wiki).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(3)
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
        response = described_class.new(wikisource).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(28)
      end
    end

    it 'functions identically on wikimedia incubator' do
      VCR.use_cassette 'replica/wikimedia_incubator_revisions' do
        all_users = [
          build(:user, username: 'Daad Ikram')
        ]

        rev_start = 2017_02_27_000000
        rev_end = 2017_02_28_000000

        incubator = Wiki.new(language: 'incubator', project: 'wikimedia')
        response = described_class.new(incubator).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(1)
      end
    end

    it 'functions identically on meta.wikimedia.org' do
      VCR.use_cassette 'replica/meta_revisions' do
        all_users = [
          build(:user, username: 'EPIC')
        ]

        rev_start = 2024_04_02_000000
        rev_end = 2024_04_03_000000

        meta = Wiki.new(language: 'meta', project: 'wikimedia')
        response = described_class.new(meta).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(6)
      end
    end

    it 'includes "File" namespace edits on Wikimedia Commons' do
      VCR.use_cassette 'replica/wikimedia_commons_revisions' do
        all_users = [
          build(:user, username: 'Oursana')
        ]

        rev_start = 2018_04_08_000000
        rev_end = 2018_04_10_000000

        commons = Wiki.new(language: 'commons', project: 'wikimedia')
        response = described_class.new(commons).get_revisions(all_users, rev_start, rev_end)
        expect(response.count).to eq(16)
      end
    end
  end

  describe 'error handling and calls ApiErrorHandling method' do
    let(:all_users) do
      [build(:user, username: 'ELE427'),
       build(:user, username: 'Ragesoss'),
       build(:user, username: 'Mrbauer1234')]
    end
    let(:rev_start) { 2014_01_01_003430 }
    let(:rev_end) { 2014_12_31_003430 }
    let(:subject) { described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end) }

    it 'handles timeout errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_raise(Errno::ETIMEDOUT)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject).to be_empty
    end

    it 'handles connection refused errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_raise(Errno::ECONNREFUSED)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject).to be_empty
    end

    it 'handles failed queries' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 200, body: '{ "success": false, "data": [] }', headers: {})
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject).to be_empty
    end

    it 'skips a wiki whose replica DB is unreachable without reporting to Sentry' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 502,
                   body: '{ "success": false, "error": "Cannot connect to database" }',
                   headers: {})
      expect_any_instance_of(described_class).not_to receive(:log_error)
      expect(Rails.logger).to receive(:warn).at_least(:once)
      expect(subject).to be_empty
    end

    it 'handles server errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 500, body: '', headers: {})
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(subject).to be_empty
    end

    it 'handles successful empty responses' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 200, body: '{ "success": true, "data": [] }', headers: {})
      expect_any_instance_of(described_class).not_to receive(:log_error)
      expect(subject).to be_empty
    end

    describe 'rate limiting (429)' do
      before do
        allow_any_instance_of(described_class).to receive(:sleep)
        # Zero jitter keeps the delay assertions below exact; jitter has its own test.
        allow_any_instance_of(described_class).to receive(:retry_jitter).and_return(0)
      end

      it 'raises Replica::RateLimitedError carrying status, body, and retry_after_seconds' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429,
                     body: 'You are making too many requests.',
                     headers: { 'Retry-After' => '30' })

        expect { subject }.to raise_error(Replica::RateLimitedError) do |error|
          expect(error.status).to eq(429)
          expect(error.response_body).to eq('You are making too many requests.')
          expect(error.retry_after_seconds).to eq(30)
        end
      end

      it 'treats a Retry-After of 0 as retry-immediately, not absent' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: { 'Retry-After' => '0' })

        expect { subject }.to raise_error(Replica::RateLimitedError) do |error|
          expect(error.retry_after_seconds).to eq(0)
        end
      end

      it 'has a nil retry_after_seconds when the header is absent' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: {})

        expect { subject }.to raise_error(Replica::RateLimitedError) do |error|
          expect(error.retry_after_seconds).to be_nil
        end
      end

      it 'has a nil retry_after_seconds when the header is present but unparseable' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '',
                     headers: { 'Retry-After' => 'Fri, 07 Nov 2014 23:59:59 GMT' })

        expect { subject }.to raise_error(Replica::RateLimitedError) do |error|
          expect(error.retry_after_seconds).to be_nil
        end
      end

      it 'does not call log_error directly -- the rate-limit error propagates instead' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: {})
        expect_any_instance_of(described_class).not_to receive(:log_error)
        expect { subject }.to raise_error(Replica::RateLimitedError)
      end

      # These four set expectations on one explicitly-constructed instance
      # (rather than going through the describe block's `subject`), since
      # that's what makes `.ordered` and per-call argument matching reliable
      # -- any_instance_of mocking does not support `.ordered`, and a second
      # any_instance_of stub in the same example does not reliably override
      # an earlier one for the same message.
      it "uses each attempt's own Retry-After as its backoff delay, then succeeds" do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(
            { status: 429, body: '', headers: { 'Retry-After' => '3' } },
            { status: 429, body: '', headers: { 'Retry-After' => '5' } },
            { status: 200, body: '{ "success": true, "data": [] }', headers: {} }
          )
        replica = described_class.new(en_wiki)
        expect(replica).to receive(:sleep).with(3).ordered
        expect(replica).to receive(:sleep).with(5).ordered

        expect(replica.get_revisions(all_users, rev_start, rev_end)).to eq({})
      end

      it 'falls back to the default delay (5s) on every attempt when Retry-After is absent' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(
            { status: 429, body: '', headers: {} },
            { status: 429, body: '', headers: {} },
            { status: 200, body: '{ "success": true, "data": [] }', headers: {} }
          )
        replica = described_class.new(en_wiki)
        expect(replica).to receive(:sleep).with(5).twice

        expect(replica.get_revisions(all_users, rev_start, rev_end)).to eq({})
      end

      it 'retries at most twice before giving up' do
        stub = stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
              .to_return(status: 429, body: '', headers: {})

        expect { subject }.to raise_error(Replica::RateLimitedError)
        expect(stub).to have_been_requested.times(3) # 1 initial attempt + 2 retries
      end

      it 'ticks update_service.record_too_many_requests for each 429 observed' do
        update_service = double('UpdateService', record_too_many_requests: nil) # rubocop:disable RSpec/VerifiedDoubles
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: {})
        # 3 tries → 3 observed 429s, same as WikiApi
        expect(update_service).to receive(:record_too_many_requests).exactly(3).times

        replica = described_class.new(en_wiki, update_service)
        expect { replica.get_revisions(all_users, rev_start, rev_end) }
          .to raise_error(Replica::RateLimitedError)
      end

      it 'caps a Retry-After-driven delay to MAX_RETRY_AFTER_SECONDS on every attempt' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: { 'Retry-After' => '1000' })
        replica = described_class.new(en_wiki)
        expect(replica).to receive(:sleep).with(30).twice

        expect { replica.get_revisions(all_users, rev_start, rev_end) }
          .to raise_error(Replica::RateLimitedError)
      end

      it 'raises an error that callers can rescue as Replica::RequestFailedError' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 429, body: '', headers: {})
        expect { subject }.to raise_error(Replica::RequestFailedError)
      end
    end

    describe 'storm guard for repeated failures' do
      let(:update_service) do
        Class.new do
          include UpdateServiceErrorHelper

          def sentry_tags
            {}
          end
        end.new
      end

      before do
        allow_any_instance_of(described_class).to receive(:sleep)
        allow(Sentry).to receive(:capture_exception)
      end

      it 'sends only the first identical failure in an update to Sentry, counting the rest' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 500, body: '', headers: {})

        2.times do
          described_class.new(en_wiki, update_service).get_revisions(all_users, rev_start, rev_end)
        end

        expect(Sentry).to have_received(:capture_exception).once
        expect(update_service.error_count).to eq(2)
      end

      it 'reports each different kind of failure once' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return({ status: 500, body: '' },
                     { status: 500, body: '' },
                     { status: 500, body: '' },
                     { status: 503, body: '' })

        2.times do
          described_class.new(en_wiki, update_service).get_revisions(all_users, rev_start, rev_end)
        end

        expect(Sentry).to have_received(:capture_exception).twice
      end

      it 'still reports every failure when there is no update service' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return(status: 500, body: '', headers: {})

        2.times { described_class.new(en_wiki).get_revisions(all_users, rev_start, rev_end) }

        expect(Sentry).to have_received(:capture_exception).twice
      end
    end
  end

  describe 'post request error handling' do
    article_titles = []
    let(:result) { described_class.new(en_wiki).post_existing_articles_by_title(article_titles) }

    it 'handles timeout errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_raise(Errno::ETIMEDOUT)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(result).to be_nil
    end

    it 'handles connection refused errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_raise(Errno::ECONNREFUSED)
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(result).to be_nil
    end

    it 'handles failed queries' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 200, body: '{ "success": false, "data": [] }', headers: {})
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(result).to be_nil
    end

    it 'skips a wiki whose replica DB is unreachable without reporting to Sentry' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 502,
                   body: '{ "success": false, "error": "Cannot connect to database" }',
                   headers: {})
      expect_any_instance_of(described_class).not_to receive(:log_error)
      expect(Rails.logger).to receive(:warn).at_least(:once)
      expect(result).to be_nil
    end

    it 'handles server errors' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 500, body: '', headers: {})
      expect_any_instance_of(described_class).to receive(:log_error).once
      expect(result).to be_nil
    end

    it 'handles successful empty responses' do
      stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
        .to_return(status: 200, body: '{ "success": true, "data": [] }', headers: {})
      expect(result).to be_empty
    end

    # POST shares api_get's 429 handling (see the GET specs above for the
    # backoff details); these just check that it's wired up.
    describe 'rate limiting (429)' do
      before do
        allow_any_instance_of(described_class).to receive(:sleep)
        allow_any_instance_of(described_class).to receive(:retry_jitter).and_return(0)
      end

      it 'backs off and retries, then succeeds' do
        stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
          .to_return({ status: 429, body: '', headers: {} },
                     { status: 200, body: '{ "success": true, "data": [] }', headers: {} })
        replica = described_class.new(en_wiki)
        expect(replica).to receive(:sleep).with(5).once

        expect(replica.post_existing_articles_by_title(article_titles)).to eq([])
      end

      it 'raises Replica::RateLimitedError once retries run out, without logging it' do
        stub = stub_request(:any, %r{#{Replica::REPLICA_TOOL_URL}.*})
               .to_return(status: 429, body: '', headers: {})
        expect_any_instance_of(described_class).not_to receive(:log_error)

        expect { result }.to raise_error(Replica::RateLimitedError)
        expect(stub).to have_been_requested.times(3)
      end
    end
  end

  describe 'rate-limit backoff jitter' do
    let(:replica) { described_class.new(en_wiki) }
    let(:error) { instance_double(Replica::RateLimitedError, retry_after_seconds: nil) }

    it 'adds random jitter on top of the backoff delay' do
      allow(replica).to receive(:rand)
        .with(0.0..Replica::MAX_RETRY_JITTER_SECONDS).and_return(0.4)
      expect(replica.send(:retry_delay_for, error)).to eq(5.4)
    end

    it 'keeps the jitter between 0 and MAX_RETRY_JITTER_SECONDS' do
      jitters = Array.new(50) { replica.send(:retry_jitter) }
      expect(jitters).to all(be_between(0.0, Replica::MAX_RETRY_JITTER_SECONDS))
    end
  end

  # Regression test for the suppressed parent revision bug.
  describe 'suppressed parent revision' do
    it 'returns correct characters for a revision with a suppressed parent revision' do
      VCR.use_cassette 'replica/suppressed_parent_revision' do
        user = build(:user, username: 'Rhitorical')
        response = described_class.new(en_wiki)
                                  .get_revisions([user], 2025_02_01_000000,
                                                 2025_06_01_000000)
        rev = response['9171866']['revisions'].find { |r| r['mw_rev_id'] == '1278154303' }

        expect(rev['characters'].to_i).to eq(1842)
      end
    end
  end

  # Without these, a silent Replica endpoint blocks the worker indefinitely.
  describe 'HTTP timeouts' do
    before do
      allow(Net::HTTP).to receive(:start).and_return(
        instance_double(Net::HTTPResponse, code: '200',
                                           body: '{"success":true,"data":[]}')
      )
    end

    it 'passes finite open_timeout and read_timeout to Net::HTTP.start for do_query' do
      described_class.new(en_wiki).send(:do_query, 'revisions.php', 'foo=bar')
      expect(Net::HTTP).to have_received(:start).with(
        anything, anything,
        hash_including(open_timeout: described_class::OPEN_TIMEOUT,
                       read_timeout: described_class::READ_TIMEOUT)
      )
    end

    it 'has positive, finite timeout constants' do
      expect(described_class::OPEN_TIMEOUT).to be > 0
      expect(described_class::READ_TIMEOUT).to be > 0
    end
  end
end


