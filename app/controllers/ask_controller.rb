require 'uri'

# Controller for ask.wikiedu.org search form
class AskController < ApplicationController
  def search
    if params[:q].blank?
      redirect_to 'http://ask.wikiedu.org'
      return
    end

    query = URI.encode(params[:q])
    redirect_to "http://ask.wikiedu.org/questions/scope:all/sort:activity-desc/page:1/query:#{query}/"
  end
end
