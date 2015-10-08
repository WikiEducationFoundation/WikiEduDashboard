require 'uri'

# Controller for ask.wikiedu.org search form
class AskController < ApplicationController
  def search
    ask_root = 'http://ask.wikiedu.org/questions/scope:all/sort:activity-desc/'

    if params[:q].blank?
      # Default to the 'student' tag
      redirect_to "#{ask_root}tags:student/page:1/"
    else
      query = URI.encode(params[:q])
      redirect_to "#{ask_root}page:1/query:#{query}/"
    end
  end
end
