# frozen_string_literal: true

# requests to pangram.com Inference API

# API docs: https://pangram.readthedocs.io/en/stable/api/rest.html
class PangramApi
  attr_reader :result

  V2_API_URL = 'https://text-extended.api.pangram.com'
  def self.v2
    new(api_url: V2_API_URL, options: { dashboard: true })
  end

  V3_API_URL = 'https://text.api.pangram.com/v3'
  def self.v3
    new(api_url: V3_API_URL, options: { public_dashboard_link: true })
  end

  def initialize(api_url:, options:)
    @options = options
    @api_url = api_url
    @api_key = ENV['pangram_api_key']
  end

  def inference(text)
    conn = Faraday.new(
      url: @api_url,
      headers: { 'Content-Type' => 'application/json', 'x-api-key' => @api_key }
    )
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env

    response = conn.post('') do |req|
      req.body = @options.merge({ text: }).to_json
    end

    @response = response
    @result = JSON.parse @response.body
  end
end
