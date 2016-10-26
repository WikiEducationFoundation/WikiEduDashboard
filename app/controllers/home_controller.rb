# frozen_string_literal: true
#= Controller for home page
class HomeController < ApplicationController
  respond_to :html
  layout 'home'

  def index
    campaign = ENV['default_campaign']
    @presenter = CoursesPresenter.new(current_user, campaign)
  end
end
