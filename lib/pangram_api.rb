# frozen_string_literal: true

# requests to pangram.com Inference API

# API docs: https://pangram.readthedocs.io/en/stable/api/rest.html
class PangramApi
  attr_reader :result

  def initialize
    @api_key = ENV['pangram_api_key']
  end

  SLIDING_WINDOW_URL = 'https://text.api.pangram.com/v3'
  def inference(text)
    conn = Faraday.new(
      url: SLIDING_WINDOW_URL,
      headers: { 'Content-Type' => 'application/json', 'x-api-key' => @api_key }
    )
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env

    response = conn.post('') do |req|
      req.body = {
        text:,
        public_dashboard_link: true
      }.to_json
    end

    @response = response
    @result = JSON.parse @response.body
  end
end
