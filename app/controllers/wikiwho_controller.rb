# frozen_string_literal: true

# Bridge for fetching authorhship data from WikiWho
class WikiwhoController < ApplicationController
  respond_to :json

  def show
    @title = params[:title]
    url = "http://wikiwho.net/wikiwho/wikiwho_api_api.py?format=json&params=author&name=#{@title}"
    @wikiwho_data = Net::HTTP::get(URI.parse(url))
    @tokens = JSON.parse(@wikiwho_data)['revisions'].values[0]['tokens']
    render json: @tokens
  end
end
