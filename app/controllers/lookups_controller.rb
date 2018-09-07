# frozen_string_literal: true

#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  before_action :require_permissions
  respond_to :json

  # Used to generate list of existing campaigns for pulldown
  def campaign
    @model = 'campaign'
    @key = 'title'
    @values = Campaign.all.order(created_at: :desc).pluck(:title)
    render 'index'
  end

  # Used to generate list of existing tags for pulldown
  def tag
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'index'
  end
end
