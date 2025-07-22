# frozen_string_literal: true

# Redirects to a user sandbox page on a wiki
class RedirectsController < ApplicationController
  before_action :require_signed_in

  ENGLISH_WIKIPEDIA = 'https://en.wikipedia.org/wiki'

  def sandbox
    uri = URI.parse(request.original_url)
    redirect_to "#{userpage}/#{params[:sandbox]}?#{uri.query}"
  end

  private

  def userpage
    "#{ENGLISH_WIKIPEDIA}/User:#{current_user.username}"
  end
end
