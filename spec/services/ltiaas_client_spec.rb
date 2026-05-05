# frozen_string_literal: true

require 'rails_helper'

describe LtiaasClient do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:url) { "https://#{domain}/api/idtoken" }

  describe '.with_ltik' do
    it 'sends LTIK-AUTH-V2 authorization header' do
      stub = stub_request(:get, url)
             .with(headers: { 'Authorization' => 'LTIK-AUTH-V2 thekey:theltik' })
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      LtiaasClient.with_ltik(domain, 'thekey', 'theltik').get('/api/idtoken')
      expect(stub).to have_been_requested
    end
  end

  describe '.with_service_auth' do
    it 'sends Bearer authorization header' do
      stub = stub_request(:get, url)
             .with(headers: { 'Authorization' => 'Bearer service-token' })
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      LtiaasClient.with_service_auth(domain, 'service-token').get('/api/idtoken')
      expect(stub).to have_been_requested
    end
  end

  describe 'response handling' do
    let(:client) { LtiaasClient.with_ltik(domain, 'k', 'l') }

    it 'returns the parsed body on 2xx' do
      stub_request(:get, url)
        .to_return(status: 200, body: '{"hello":"world"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect(client.get('/api/idtoken')).to eq({ 'hello' => 'world' })
    end

    it 'raises LtiaasClientError on 4xx (non-auth, non-429)' do
      stub_request(:get, url).to_return(status: 400, body: 'bad')

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasClientError) do |err|
          expect(err.status_code).to eq(400)
        end
    end

    it 'raises LtiaasAuthError on 401' do
      stub_request(:get, url).to_return(status: 401, body: 'no auth')

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasAuthError)
    end

    it 'raises LtiaasAuthError on 403' do
      stub_request(:get, url).to_return(status: 403, body: 'forbidden')

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasAuthError)
    end

    it 'raises LtiaasRateLimitError on 429' do
      stub_request(:get, url).to_return(status: 429, body: 'slow down')

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasRateLimitError)
    end

    it 'raises LtiaasTransientError on 5xx' do
      stub_request(:get, url).to_return(status: 502, body: 'gateway')

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasTransientError)
    end

    it 'raises LtiaasTransientError on connection failure' do
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new('refused'))

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasTransientError, /network failure/)
    end

    it 'raises LtiaasTransientError on timeout' do
      stub_request(:get, url).to_raise(Faraday::TimeoutError)

      expect { client.get('/api/idtoken') }
        .to raise_error(LtiaasClient::LtiaasTransientError, /network failure/)
    end
  end

  describe 'verbs' do
    let(:client) { LtiaasClient.with_ltik(domain, 'k', 'l') }
    let(:body) { { 'foo' => 'bar' } }

    it 'POSTs JSON body' do
      stub = stub_request(:post, "https://#{domain}/api/lineitems")
             .with(body: { foo: 'bar' }.to_json)
             .to_return(status: 200, body: '{}',
                        headers: { 'Content-Type' => 'application/json' })

      client.post('/api/lineitems', body)
      expect(stub).to have_been_requested
    end

    it 'PUTs JSON body' do
      stub = stub_request(:put, "https://#{domain}/api/lineitems/1")
             .with(body: { foo: 'bar' }.to_json)
             .to_return(status: 200, body: '{}',
                        headers: { 'Content-Type' => 'application/json' })

      client.put('/api/lineitems/1', body)
      expect(stub).to have_been_requested
    end

    it 'DELETEs' do
      stub = stub_request(:delete, "https://#{domain}/api/lineitems/1")
             .to_return(status: 200, body: '{}',
                        headers: { 'Content-Type' => 'application/json' })

      client.delete('/api/lineitems/1')
      expect(stub).to have_been_requested
    end
  end
end
