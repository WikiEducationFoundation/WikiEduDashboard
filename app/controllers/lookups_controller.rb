# frozen_string_literal: true

#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  respond_to :json

  # Used to generate list of existing campaigns for pulldown
  def campaign
    @model = 'campaign'
    @key = 'title'
    @values = Campaign.all.order(created_at: :desc)
    render 'campaigns'
  end

  # Used to generate list of existing tags for pulldown
  def tag
    require_admin_permissions
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'tags'
  end
end
