# frozen_string_literal: true

require 'uri'

# Controller for ask.wikiedu.org search form
class AskController < ApplicationController
  ASK_ROOT = 'https://ask.wikiedu.org/questions/scope:all/sort:relevance-desc/'

  def search
    if params[:q].blank?
      # Default to the 'student' tag
      redirect_to "#{ASK_ROOT}tags:student/page:1/"
    else
      log_to_sentry
      query = URI.encode(params[:q])
      redirect_to "#{ASK_ROOT}page:1/query:#{query}/"
    end
  end

  private

  def log_to_sentry
    # Logging to see how this feature gets used
    Raven.capture_message 'ask.wikiedu.org query',
                          level: 'info',
                          tags: { 'source' => params[:source], 'query' => params[:q] },
                          extra: { query: params[:q], username: current_user&.username }
  end
end
